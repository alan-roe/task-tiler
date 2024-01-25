"use strict"
import * as logseq from "../../node_modules/@logseq/libs/dist/lsplugin.user.js"

// logseq
export function ready(f) {
  return () => {
    window.logseq.ready(f).catch(console.error);
  }
}

// UI
async function showMsg(x) {
  console.log(`showMsg ${x}`)
  return window.logseq.UI.showMsg(x, "error")
}

export const showMsgImpl = x => () => showMsg(x)
