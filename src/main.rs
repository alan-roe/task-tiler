use std::rc::Rc;

mod parser;

use parser::load_tasks;
use slint::{Color, ModelRc, Timer, TimerMode, VecModel};
slint::include_modules!();

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
    let t = load_tasks(tasks_str);
    println!("{:?}", t);
    let tasks = vec![
        vec![
            TaskStruct {
                abbr: "DB".into(),
                color: Color::from_argb_encoded(0xffc25e88),
                allot: 60 * 60,
                blocks: 1.0,
                spent: 0,
                title: "Database".into(),
                info: "- Complete test\n- Complete Lab".into(),
                idx: ModelRc::new(VecModel::from(vec![0, 0])),
            },
            TaskStruct {
                abbr: "Web".into(),
                color: Color::from_argb_encoded(0xff0081ce),
                allot: 60 * 60 * 3,
                blocks: 3.0,
                spent: 0,
                title: "Website".into(),
                info: "- Finish hire page templates\n- Message about hire page content".into(),
                idx: ModelRc::new(VecModel::from(vec![0, 1])),
            },
        ],
        vec![
            TaskStruct {
                abbr: "Hobby".into(),
                color: Color::from_argb_encoded(0xff5a74cb),
                allot: 60 * 60 * 3,
                blocks: 3.0,
                spent: 0,
                title: "Hobby".into(),
                info: "- Task Manager".into(),
                idx: ModelRc::new(VecModel::from(vec![1, 0])),
            },
            TaskStruct {
                abbr: "Java".into(),
                color: Color::from_argb_encoded(0xffa265af),
                allot: 60 * 60,
                blocks: 1.0,
                spent: 0,
                title: "Java".into(),
                info: "- Do a test\n- Read the book".into(),
                idx: ModelRc::new(VecModel::from(vec![1, 1])),
            },
        ],
    ];

    let tasks: Vec<ModelRc<TaskStruct>> = tasks
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
