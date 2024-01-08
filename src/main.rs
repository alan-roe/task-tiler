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
    bottom = bottom.into_iter().enumerate().map(|(i, mut t1)| {
        t1.idx = ModelRc::new(VecModel::from(vec![1, i as i32]));
        t1
    }).collect();

    Vec::from([top, bottom])
}

fn main() -> Result<(), slint::PlatformError> {
    let tasks_str = r#"- Java
	- 1hr
		- First Test
		- Study
		- Second Test

- Databases
	- 1hr
		- Assignment Work
- Hire86 Website
	- 3 hr
		- Create all basic product pages
		- Message them about content
			- Send theorised layout, be open to differences of opinion
- Hobby Projects
	- 3 hr
		- Maybe I could make something that turns this layout of time management into something more readable, visual. I wish my remarkable was working
		- There are some interesting designs worth exploring. Perhaps I can mock some up in figma. There's a certain genre of red that I'm looking for, a pale one. I see matching blues and yellows, greens, purple, orange.
		- Making it an app doesn't seem convenient, maybe an app that can be always on top somewhere, or only chime in when necessary. Or the ESP32 just always running on my desktop. Slint? Too early to decide on implementation? ESP32 would be less portable unless I got it hooked up to batteries with a switch. A phone app would be too much of a battery drain to have open all the time. Maybe an always on top desktop app would jump out of the cursor's way. I can imagine pushing it around the screen, with it popping out the other side when pushed against a wall.
		- Important for each task
			- Data:
				- Title
				- Time Spent
			- Actions:
				- if working
					- Stop Work
				- else if any child has children
					- Open Task
				- else
					- Start Work
"#;
    let mut color_gen = ColorGen::start_gen();
    let t = load_tasks(tasks_str);
    println!("{:?}", &t);
    let t: Vec<TaskStruct> = t.into_iter().map(|task| {
        println!("{:?}", &task);
        TaskStruct {
            abbr: task.title.clone().into(),
            color: color_gen.next_colour(),
            title: task.title.into(),
            info: task.info.into(),
            allot: task.allot as i32,
            spent: 0,
            blocks: task.blocks,
            idx: ModelRc::new(VecModel::from(vec![0, 1]))
        }
    }).collect();
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
            if ui.get_show_info() {
                ui.invoke_update_time();
            }
        },
    );

    ui.run()
}
