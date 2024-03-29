use std::{iter::Cycle, rc::Rc};

use std::time::Duration;
#[cfg(not(target_family = "wasm"))]
use std::time::SystemTime;
#[cfg(target_family = "wasm")]
use wasmtimer::std::SystemTime;
mod parser;

use iter_tools::Itertools;
use parser::{to_json, Task};
use rand::{seq::SliceRandom, thread_rng};
use slint::{Color, ModelRc, Timer, TimerMode, VecModel};
slint::include_modules!();

use async_trait::async_trait;
use ezsockets::ClientConfig;

use std::sync::mpsc;
use std::sync::mpsc::{Receiver, Sender};

struct Client {
    task_sender: Sender<String>,
    handle: ezsockets::Client<Self>,
}

#[async_trait]
impl ezsockets::ClientExt for Client {
    type Call = String;

    async fn on_text(&mut self, text: String) -> Result<(), ezsockets::Error> {
        println!("received message: {text}");
        self.task_sender.send(text).expect("can't send tasks");
        Ok(())
    }

    async fn on_binary(&mut self, bytes: Vec<u8>) -> Result<(), ezsockets::Error> {
        println!("received bytes: {bytes:?}");
        Ok(())
    }

    async fn on_call(&mut self, call: Self::Call) -> Result<(), ezsockets::Error> {
        self.handle.text(call).unwrap();
        Ok(())
    }
}

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
                info: ModelRc::new(VecModel::from(
                    task.info
                        .iter()
                        .map(|info| InfoStruct {
                            info: (&info.info).into(),
                            checkbox: info.checkbox,
                            tabs: "  ".repeat(info.tabs).into(),
                        })
                        .collect_vec(),
                )),
                allot: task.allot as i32,
                spent: task.spent as f32,
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
    timer: Rc<Timer>,
    receive_timer: Rc<Timer>,
    handle: ezsockets::Client<Client>,
}

impl Ui {
    fn load_ui(
        task_receiver: Receiver<String>,
        handle: ezsockets::Client<Client>,
    ) -> Result<Self, slint::PlatformError> {
        let ui = AppWindow::new()?;
        let ui_handle = ui.as_weak();
        let app = Self {
            ui,
            timer: Rc::new(Timer::default()),
            receive_timer: Rc::new(Timer::default()),
            handle,
        };

        app.receive_timer.start(
            TimerMode::Repeated,
            Duration::from_millis(1000),
            move || {
                if let Ok(task_str) = task_receiver.try_recv() {
                    let ui_handle = ui_handle.clone();
                    slint::invoke_from_event_loop(move || {
                        send_tasks(&ui_handle.unwrap(), parser::from_json(&task_str).unwrap());
                    })
                    .unwrap();
                }
            },
        );

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
                Duration::from_millis(1000),
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
        let stop_handle = self.handle.clone();
        self.ui.on_stop_timer(move || {
            stop_timer.stop();
            let t = Task {
                title: "sending from the thingy".to_string(),
                allot: 0,
                spent: 0,
                info: vec![],
                checkbox: CheckBoxState::None,
            };
            // stop_handle.text(to_json(&t)).unwrap();
        });

        self.ui.run()
    }
}

#[cfg(not(target_family = "wasm"))]
#[tokio::main]
pub async fn main() -> Result<(), slint::PlatformError> {
    // let tasks_str: String = File::open("./test.md")
    // .map(|mut f| {
    //     let mut s = String::new();
    //     f.read_to_string(&mut s)
    //         .expect("couldn't read data from file");
    //     s
    // })
    // .unwrap();

    // let tasks = load_tasks(&tasks_str);

    let config = ClientConfig::new("ws://localhost:8080/websocket");
    let (task_sender, task_receiver) = mpsc::channel();
    let (handle, _future) = ezsockets::connect(
        |handle| Client {
            task_sender,
            handle,
        },
        config,
    )
    .await;

    let ui: Ui = Ui::load_ui(task_receiver, handle)?;

    ui.run()
}

#[cfg(target_family = "wasm")]
#[wasm_bindgen::prelude::wasm_bindgen(main)]
async fn main() -> Result<(), wasm_bindgen::JsValue> {
    use std::sync::Arc;
    console_error_panic_hook::set_once();
    tracing_wasm::set_as_global_default();

    let config = ClientConfig::new("ws://192.168.1.203:8080/websocket").socket_config(
        ezsockets::SocketConfig {
            heartbeat_ping_msg_fn: Arc::new(|_t: Duration| {
                ezsockets::RawMessage::Binary("ping".into())
            }),
            ..Default::default()
        },
    );
    let (task_sender, task_receiver) = mpsc::channel();
    let (_client, mut handle) = ezsockets::connect_with(
        |_client| Client { task_sender },
        config,
        ezsockets::ClientConnectorWasm::default(),
    );

    let ui: Ui = Ui::load_ui(task_receiver).unwrap();

    ui.run();

    Ok(())
}
