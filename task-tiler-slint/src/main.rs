use std::fs::File;
use std::io::Read;
use std::thread;
use std::time::SystemTime;
use std::{iter::Cycle, rc::Rc};

use rumqttc::{MqttOptions, Client, QoS, Event::*, ConnectReturnCode};
use std::time::Duration;
mod parser;

use iter_tools::Itertools;
use parser::{load_tasks, Task};
use rand::{seq::SliceRandom, thread_rng};
use rumqttc::Packet;
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

fn split_tasks(tasks: Vec<TaskStruct>) -> Vec<Vec<TaskStruct>> {
    let mut top: Vec<TaskStruct> = Vec::new();
    let mut bottom: Vec<TaskStruct> = Vec::new();
    tasks
        .into_iter()
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

fn generate_blocks(tasks: &[Task]) -> Vec<f32> {
    let total = tasks.iter().fold(0, |acc, t| acc + t.allot);
    // let num = tasks.len() as u64;
    let block_size = total / 8;
    tasks
        .iter()
        .map(|task| task.allot as f32 / block_size as f32)
        .collect_vec()
}

fn send_tasks(ui: &AppWindow, tasks: Vec<Task>) {
    let mut color_gen = ColorGen::start_gen();
    let mut blocks = generate_blocks(&tasks).into_iter();
    let tasks: Vec<Vec<TaskStruct>> = split_tasks(
        tasks
            .iter()
            .map(|task| TaskStruct {
                abbr: task.title.clone().into(),
                color: color_gen.next_colour(),
                title: (&task.title).into(),
                info: (&task.info).into(),
                allot: task.allot as i32,
                spent: 0.0,
                blocks: blocks.next().unwrap(),
                idx: ModelRc::new(VecModel::from(vec![0, 1])),
                started: false,
            })
            .collect_vec(),
    );
    let slint_tasks: Vec<ModelRc<TaskStruct>> = tasks
        .into_iter()
        .map(VecModel::from)
        .map(Rc::new)
        .map(Into::into)
        .collect();
    ui.set_tasks(Rc::new(VecModel::from(slint_tasks)).into());
}

struct Ui {
    ui: AppWindow,
    timer: Rc<Timer>
}

impl Ui {
    fn load_ui() -> Result<Self, slint::PlatformError> {

        let ui = AppWindow::new()?;
        let ui_handle = ui.as_weak();
        let app = Self {
            ui,
            timer: Rc::new(Timer::default()),
        };

        thread::spawn(move || {
            let ui_handle = ui_handle;
            loop {
                let mut mqttoptions = MqttOptions::new("task-tiler-rust", "192.168.1.153", 1883);
                mqttoptions.set_credentials("task-tiler-rust", "task-tiler-rust");
                mqttoptions.set_keep_alive(Duration::from_secs(5));
                let (mut client, mut connection) = Client::new(mqttoptions, 10);
                
                for event in connection.iter().flatten() {
                    match event {
                        Incoming(Packet::ConnAck(connack)) => {
                            if connack.code == ConnectReturnCode::Success {
                                client.subscribe("tasks", QoS::AtMostOnce).unwrap();
                            }
                        },
                        Incoming(Packet::Publish(publish)) => {
                            let ui_handle = ui_handle.clone();
                            slint::invoke_from_event_loop(move || {
                                let t = String::from_utf8(publish.payload.to_vec()).unwrap();
                                send_tasks(&ui_handle.unwrap(), load_tasks(&t));
                            }).unwrap();
                        },
                        _ => {}
                    }
                }
            }
        });
        
        Ok(app)
    }

    fn run(&self) -> Result<(), slint::PlatformError> {
        let ui_handle = self.ui.as_weak();
        let start_timer = self.timer.clone();
        let stop_timer = start_timer.clone();
        self.ui.on_start_timer(move || {
            let sys_time = SystemTime::now();
            let ui_handle = ui_handle.clone();
            let last_spent = ui_handle.clone().unwrap().get_current_spent();
            start_timer.start(
                TimerMode::Repeated,
                std::time::Duration::from_millis(1000),
                move || {
                    let elapsed = match sys_time.elapsed() {
                        Ok(t) => t,
                        Err(t) => t.duration(),
                    };
                    let time = last_spent + elapsed.as_secs_f32();
                    ui_handle.unwrap().invoke_update_time(time);
                },
            );
        });

        self.ui.on_stop_timer(move || {
            stop_timer.stop();
        });

        self.ui.run()
    }
}

fn main() -> Result<(), slint::PlatformError> {
    // let tasks_str: String = File::open("./test.md")
    // .map(|mut f| {
    //     let mut s = String::new();
    //     f.read_to_string(&mut s)
    //         .expect("couldn't read data from file");
    //     s
    // })
    // .unwrap();

    // let tasks = load_tasks(&tasks_str);

    let ui: Ui = Ui::load_ui()?;

    ui.run()
}