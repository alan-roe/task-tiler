use std::{iter::Cycle, rc::Rc};

mod parser;

use parser::load_tasks;
use rand::{seq::SliceRandom, thread_rng};
use slint::{Color, ModelRc, Timer, TimerMode, VecModel};
slint::include_modules!();

struct ColorGen {
    color_bank: Cycle<std::vec::IntoIter<slint::Color>>,
}

const PALLETE: &[u32] = &[
    0xffc25e88, 0xffa265af, 0xff5a74cb, 0xff0081ce, 0xff0086b2, 0xff00867e, 0xfffd93bd, 0xffffe4f5,
];

impl ColorGen {
    pub fn start_gen() -> ColorGen {
        let mut color_bank = Vec::from(PALLETE)
            .iter()
            .map(|c| Color::from_argb_encoded(*c))
            .collect::<Vec<Color>>();
        color_bank.shuffle(&mut thread_rng());
        ColorGen {
            color_bank: color_bank.into_iter().cycle(),
        }
    }
    pub fn next_colour(&mut self) -> Color {
        self.color_bank.next().unwrap()
    }
}

fn split_tasks(mut tasks: Vec<TaskStruct>) -> Vec<Vec<TaskStruct>> {
    let mut top: Vec<TaskStruct> = Vec::new();
    let mut bottom: Vec<TaskStruct> = Vec::new();
    tasks.sort_by(|t1, t2| t1.blocks.total_cmp(&t2.blocks));
    let tasks_iter = tasks.into_iter().rev();

    for mut t1 in tasks_iter {
        let current_top = top.iter().fold(0.0, |acc, x| acc + x.blocks);
        if current_top + t1.blocks <= 4.0 {
            t1.idx = ModelRc::new(VecModel::from(vec![0, top.len() as i32]));
            top.push(t1);
        } else {
            bottom.insert(0, t1);
        }
    }
    bottom = bottom
        .into_iter()
        .enumerate()
        .map(|(i, mut t1)| {
            t1.idx = ModelRc::new(VecModel::from(vec![1, i as i32]));
            t1
        })
        .collect();

    Vec::from([top, bottom])
}

fn main() -> Result<(), slint::PlatformError> {
    let tasks_str = r#"- Fitness
	- 1hr
		- find basic bodyweight moves
		- do them
- [[Tiling Task Manager]]
	- 1hr
		- refactor?
		- load in files
		- read minutes
		- clip titles if overflow
"#;
    let mut color_gen = ColorGen::start_gen();
    let t = load_tasks(tasks_str);
    println!("{:?}", &t);
    let t: Vec<TaskStruct> = t
        .into_iter()
        .map(|task| {
            println!("{:?}", &task);
            TaskStruct {
                abbr: task.title.clone().into(),
                color: color_gen.next_colour(),
                title: task.title.into(),
                info: task.info.into(),
                allot: task.allot as i32,
                spent: 0,
                blocks: task.blocks,
                idx: ModelRc::new(VecModel::from(vec![0, 1])),
                started: false,
            }
        })
        .collect();
    let t = split_tasks(t);

    let tasks: Vec<ModelRc<TaskStruct>> = t
        .into_iter()
        .map(VecModel::from)
        .map(Rc::new)
        .map(Into::into)
        .collect();
    let tasks = Rc::new(VecModel::from(tasks));

    let ui = AppWindow::new()?;
    let ui_handle = ui.as_weak();
    ui.set_tasks(tasks.into());
    let timer = Timer::default();
    timer.start(
        TimerMode::Repeated,
        std::time::Duration::from_millis(1000),
        move || {
            let ui = ui_handle.unwrap();
            if ui.get_task_started() {
                ui.invoke_update_time();
            }
        },
    );

    ui.run()
}
