use std::rc::Rc;

use slint::{Color, ModelRc, Timer, TimerMode, VecModel};

slint::include_modules!();

fn main() -> Result<(), slint::PlatformError> {
    let ui = AppWindow::new()?;
    let ui_handle = ui.as_weak();

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
