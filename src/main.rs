use std::fs::File;
use std::io::Read;
use std::time::Instant;
use std::{iter::Cycle, rc::Rc};

mod parser;

use iter_tools::Itertools;
use parser::{load_tasks, Task};
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

fn split_tasks<T: DoubleEndedIterator<Item = TaskStruct>>(tasks: T) -> Vec<Vec<TaskStruct>> {
    let mut top: Vec<TaskStruct> = Vec::new();
    let mut bottom: Vec<TaskStruct> = Vec::new();
    tasks
        .sorted_by(|t1, t2| t1.blocks.total_cmp(&t2.blocks))
        .rev()
        .for_each(|mut t1| {
            let current_top = top.iter().fold(0.0, |acc, x| acc + x.blocks);
            if current_top + t1.blocks <= 4.0 {
                t1.idx = ModelRc::new(VecModel::from(vec![0, top.len() as i32]));
                top.push(t1);
            } else {
                bottom.insert(0, t1);
            }
        });

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

fn send_tasks(ui: &AppWindow, tasks: Vec<Task>) {
    let mut color_gen = ColorGen::start_gen();

    let tasks: Vec<Vec<TaskStruct>> = split_tasks(tasks.into_iter().map(|task| {
        println!("{:?}", &task);
        TaskStruct {
            abbr: task.title.clone().into(),
            color: color_gen.next_colour(),
            title: task.title.into(),
            info: task.info.into(),
            allot: task.allot as i32,
            spent: 0.0,
            blocks: task.blocks,
            idx: ModelRc::new(VecModel::from(vec![0, 1])),
            started: false,
        }
    }));
    let slint_tasks: Vec<ModelRc<TaskStruct>> = tasks
        .into_iter()
        .map(VecModel::from)
        .map(Rc::new)
        .map(Into::into)
        .collect();
    ui.set_tasks(Rc::new(VecModel::from(slint_tasks)).into());
}

fn main() -> Result<(), slint::PlatformError> {
    // Load in a test plan
    let tasks_str: String = File::open("./test.md")
        .map(|mut f| {
            let mut s = String::new();
            f.read_to_string(&mut s)
                .expect("couldn't read data from file");
            s
        })
        .unwrap();
    let tasks = load_tasks(&tasks_str);

    let ui = AppWindow::new()?;
    send_tasks(&ui, tasks);
    
    let ui_handle = ui.as_weak();
    let timer = Timer::default();
    let start_timer = Rc::new(timer);
    let stop_timer = start_timer.clone();
    ui.on_start_timer(move || {
        let instant = Instant::now();
        let ui_handle = ui_handle.clone();
        let last_spent = ui_handle.clone().unwrap().get_current_spent();
        start_timer.start(
            TimerMode::Repeated,
            std::time::Duration::from_millis(1000),
            move || {
                let ui = ui_handle.unwrap();
                let time = last_spent + Instant::now().duration_since(instant).as_secs_f32();
                ui.invoke_update_time(time);
            },
        );
    });

    ui.on_stop_timer(move || {
        stop_timer.stop();
    });

    ui.run()
}
