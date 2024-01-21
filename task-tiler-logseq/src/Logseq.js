"use strict"
const logseq = require("@logseq/libs")

const ls = window.logseq

async function showMsg(x) {
  console.log(`showMsg ${x}`)
  return ls.UI.showMsg(x, "error")
}

export const showMsgImpl = x => () => showMsg(x)

export function ready(f) {
  return () => {
    ls.ready(f).catch(console.error);
  }
}

export function registerSlashCommandImpl(name, f) {
  return () => {
    ls.Editor.registerSlashCommand(name, f)
  }
}