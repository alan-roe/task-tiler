export function registerSlashCommandImpl(name, f) {
  return () => {
    window.logseq.Editor.registerSlashCommand(name, f)
  }
}
  
// fetches an 
function getEntity(entity, tuple, b) {
  if(b.uuid) {
    return entity(b)
  } 
  return tuple(b[1])
}

function loadBlock(just, nothing, left, right, block) {
  let childrenArr = [];
  if(block.children) {
    for(child of block.children) {
      childrenArr.push(getEntity(left, right, child))
    }
  }
  return {
    parent: block.parent.id,
    children: childrenArr.length > 0 ? just(childrenArr) : nothing,
    content: block.content
  };
}

async function getCurrentBlock(just, nothing, left, right) {
  let block = await window.logseq.Editor.getCurrentBlock();
  if(!block) {
    return nothing
  }
  return just(loadBlock(just, nothing, left, right, block))
}

export const getCurrentBlockImpl = just => nothing => left => right => () => getCurrentBlock(just, nothing, left, right)

async function getBlock(just, nothing, left, right, id) {
  let block = await window.logseq.Editor.getBlock(id);
  if(!block) {
    return nothing;
  }

  return just(loadBlock(just, nothing, left, right, block));
}

export const getBlockNImpl = just => nothing => left => right => id => () => getBlock(just, nothing, left, right, id)
export const getBlockUImpl = just => nothing => left => right => id => () => getBlock(just, nothing, left, right, id)
