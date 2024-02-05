# Task Tiler Client

## Overview

The Task Tiler Client, currently available as a desktop and web application, enables users to visually manage the tasks sent from Logseq via the [Task Tiler Plugin](../task-tiler-logseq). It displays tasks as tiles, sized in relation to how much time has been allotted for them, making it easy to view and manage them.

![Home](.github/images/home.png)
![Task](.github/images/task.png)

## Functionality

- [x]   Retrieve tasks via [Task Tiler Server](../task-tiler-server/) and display them in tiles
- [x]   View more info about tasks
- [x]   Track time spent on tasks
- [ ]   Edit tasks
- [ ]   Send updated tasks back to broker
- [ ]   ESP32 client
- [x]   Web client

## Installation and Setup

- [ ]   Installation guide
- [ ]   Instructions for linking with Logseq

## Building from source
To run the desktop client use `cargo run --features desktop`

To build a wasm package and launch a server use `cargo run --target wasm32-unknown-unknown --features web --release`
I use the `--release` flag because the debug build runs very slowly. It uses [wasm-server-runner](https://github.com/jakobhellermann/wasm-server-runner) as the runner. 