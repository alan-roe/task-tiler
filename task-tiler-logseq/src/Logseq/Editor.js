const ls = window.logseq

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
    return tuple(b[1])
  }
  
  async function getCurrentBlock(just, nothing, left, right) {
    let block = await ls.Editor.getCurrentBlock();
    if(!block) {
      return nothing
    }
    let childrenArr = [];
    if(block.children) {
      for(child of block.children) {
        childrenArr.push(getEntity(left, right, child))
      }
    }
    return just({
        children: childrenArr.length > 0 ? just(childrenArr) : nothing,
        content: block.content
      })
  }
  
  export const getCurrentBlockImpl = just => nothing => left => right => () => getCurrentBlock(just, nothing, left, right)