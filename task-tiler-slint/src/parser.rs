use iter_tools::Itertools;
use serde::{Deserialize, Serialize};
#[derive(Debug, Serialize, Deserialize)]
pub struct Task {
    pub title: String,
    pub allot: u64,
    pub spent: u64,
    pub info: String,
}

pub fn from_json(json: &str) -> serde_json::Result<Vec<Task>> {
    let tasks: Vec<Task> = dbg!(serde_json::from_str(json)?);
    Ok(tasks)
}

fn load_info<T: AsRef<str>>(info: &[T]) -> String {
    let info_iter = info.iter().map(|x| x.as_ref().to_string()).collect_vec();
    let tab_size = info_iter[0].chars().take_while(|x| x != &'-').count();
    info_iter
        .into_iter()
        .map(|mut x| x.split_off(tab_size).replace('\t', "  "))
        .reduce(|acc, s| acc + "\n" + &s)
        .unwrap_or(info[0].as_ref()[tab_size..].to_string())
}

fn load_task(task: Vec<&str>) -> Task {
    Task {
        title: load_title(task[0]),
        allot: load_time(&task[1].trim()[2..]),
        spent: 0,
        info: load_info(&task[2..]),
    }
}

fn load_title(task: &str) -> String {
    task.replace("[[", "").replace("]]", "")
}

fn load_time(trim: &str) -> u64 {
    let mut time = 0;
    let mut h_idx = 0;
    if let Some(x) = trim.find('h') {
        time += 60 * 60 * (trim[0..x].trim().parse::<u64>().unwrap());
        h_idx = x + 2;
    }
    if let Some(x) = trim.find('m') {
        time += 60 * trim[h_idx..x].trim().parse::<u64>().unwrap();
    }
    time
}

/// Loads tasks
#[allow(dead_code)]
pub fn load_tasks(tasks: &str) -> Vec<Task> {
    tasks[2..]
        .split("\n- ")
        .map(|split| split.lines().collect_vec())
        .map(load_task)
        .collect_vec()
}

mod tests {
    fn _load_tasks() -> Vec<super::Task> {
        super::load_tasks(
            r#"- Java
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
"#,
        )
    }

    #[test]
    fn load_titles() {
        let loaded = _load_tasks();
        let mut loaded_iter = loaded.iter();
        assert_eq!(loaded_iter.next().unwrap().title, "Java");
        assert_eq!(loaded_iter.next().unwrap().title, "Databases");
        assert_eq!(loaded_iter.next().unwrap().title, "Hire86 Website");
        assert_eq!(loaded_iter.next().unwrap().title, "Hobby Projects");
    }

    #[test]
    fn load_info() {
        let loaded = _load_tasks();
        let mut loaded_iter = loaded.iter();
        assert_eq!(
            loaded_iter.next().unwrap().info,
            "- First Test
- Study
- Second Test"
        );
        assert_eq!(loaded_iter.next().unwrap().info, "- Assignment Work");
        assert_eq!(
            loaded_iter.next().unwrap().info,
            "- Create all basic product pages
- Message them about content
    - Send theorised layout, be open to differences of opinion"
        );
        assert_eq!(loaded_iter.next().unwrap().info, "- Maybe I could make something that turns this layout of time management into something more readable, visual. I wish my remarkable was working
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
            - Start Work");
    }

    #[test]
    fn load_allot() {
        let tasks = _load_tasks();
        let mut tasks_iter = tasks.iter();
        assert_eq!(tasks_iter.next().unwrap().allot, 60 * 60);
        assert_eq!(tasks_iter.next().unwrap().allot, 60 * 60);
        assert_eq!(tasks_iter.next().unwrap().allot, 60 * 60 * 3);
        assert_eq!(tasks_iter.next().unwrap().allot, 60 * 60 * 3);
    }
}
