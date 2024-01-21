"use strict"
const logseq = require("@logseq/libs")

const ls = window.logseq

// logseq
export function ready(f) {
  return () => {
    ls.ready(f).catch(console.error);
  }
}

// UI
async function showMsg(x) {
  console.log(`showMsg ${x}`)
  return ls.UI.showMsg(x, "error")
}

export const showMsgImpl = x => () => showMsg(x)

// Editor
export function registerSlashCommandImpl(name, f) {
  return () => {
    ls.Editor.registerSlashCommand(name, f)
  }
}

// fetches an 
function getEntity(entity, tuple, b) {
  if(b.uuid) {
    return entity(b)
  } 
  return tuple(b)
}

async function getCurrentBlock(just, nothing, left, right) {
  let block = await ls.Editor.getCurrentBlock();
  if(!block) {
    return nothing()
  }
  let childrenArr = [];
  if(block.children) {
    for(child of block.children) {
      childrenArr.push(getEntity(left, right, child))
      console.log(child[1])
    }
  }
  let ret = {
    children: childrenArr.length > 0 ? just(childrenArr) : nothing(),
    content: block.content
  };
  console.log(ret.content)
  return just(ret)
}

export const getCurrentBlockImpl = just => nothing => left => right => () => getCurrentBlock(just, nothing, left, right)