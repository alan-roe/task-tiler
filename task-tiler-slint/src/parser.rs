use crate::CheckBoxState;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct Info {
    pub info: String,
    pub tabs: usize,
    pub checkbox: CheckBoxState,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Task {
    pub title: String,
    pub allot: u64,
    pub spent: u64,
    pub info: Vec<Info>,
    pub checkbox: CheckBoxState,
}

pub fn from_json(json: &str) -> serde_json::Result<Vec<Task>> {
    let tasks: Vec<Task> = dbg!(serde_json::from_str(json)?);
    Ok(tasks)
}

pub fn to_json(task: &Task) -> String {
    dbg!(serde_json::to_string(task).unwrap())
}