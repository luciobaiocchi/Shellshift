const notice=document.querySelector('#notice');
const canvas=document.querySelector('canvas');
let lastPacket, lastPairs, ready=false;
function command(text){if(window.FTEC?.evcb?.cbufaddtext)window.FTEC.cbufadd(text+'\n');}
function notify(text){window.parent.postMessage({type:text},'*');}
function report(line){
  console.log(line);
  if(line.includes('SHELLSHIFT_READY')){
    ready=true;notice.hidden=true;canvas.focus();notify('sector-ready');
  }
  if(line.includes('SHELLSHIFT_PASS'))notify('sector-pass');
  if(/unable to initialize renderer|failed to initialise renderer|couldn.t initialize.*renderer|no available video device/i.test(line)){
    notice.hidden=false;notice.textContent='FTEQW richiede WebGL. Attiva l’accelerazione grafica oppure usa un browser con WebGL disponibile.';
  }
}
window.addEventListener('message',e=>{
  if(e.source!==window.parent || e.data?.type!=='sector-state'||!ready)return;
  const {packet,pairs,active}=e.data;
  if(!active){for(const k of ['forward','back','left','right','moveleft','moveright'])command('-'+k);return;}
  if(Number.isInteger(packet)&&packet>=-1&&packet<=100&&packet!==lastPacket){command('set sh_packet '+packet);lastPacket=packet;}
  if((pairs===1||pairs===2)&&pairs!==lastPairs){command('set sh_pairs '+pairs);lastPairs=pairs;}
});
window.addEventListener('keydown',e=>{if(e.key==='Escape'){e.preventDefault();notify('sector-exit');}},true);
for(const button of document.querySelectorAll('[data-cmd]')){
  button.onpointerdown=e=>{e.preventDefault();button.setPointerCapture(e.pointerId);command('+'+button.dataset.cmd);};
  button.onlostpointercapture=()=>command('-'+button.dataset.cmd);
}
async function bytes(name){
  const r=await fetch(name);if(!r.ok)throw new Error(name+' · HTTP '+r.status);
  return r.arrayBuffer();
}
async function start(){
  if(location.protocol==='file:'){notice.textContent='Avvia Shellshift via HTTP. Nella cartella estratta esegui python3 serve.py, poi apri l’indirizzo indicato.';return;}
  const diagnostic=location.search==='?diagnostic';
  const hasGL=document.createElement('canvas').getContext('webgl');
  if(!hasGL&&!diagnostic){notice.textContent='Il browser non offre WebGL. Per entrare nel Settore Nero serve un browser con accelerazione grafica.';return;}
  if(hasGL)hasGL.getExtension('WEBGL_lose_context')?.loseContext();
  const [wasm,manifest,pk3]=await Promise.all(['engine/ftewebgl.wasm','default.fmf','game/sector.pk3'].map(bytes));
  window.Module={canvas,wasmBinary:new Uint8Array(wasm),
    files:{'default.fmf':manifest,'sector/pak0.pk3':pk3},
    arguments:[...(diagnostic?['-dedicated']:[]),'-nohome','+set','sv_public','0','+set','developer','1','+exec','sector.cfg','+map','void'],
    print:report,printErr:report,onAbort:()=>{notice.hidden=false;notice.textContent='Il motore si è fermato. Rientra al desktop e riapri il settore.';}};
  const script=document.createElement('script');script.src='engine/ftewebgl.js';document.body.appendChild(script);
}
start().catch(e=>{notice.textContent='Avvio non riuscito · '+e.message;});
