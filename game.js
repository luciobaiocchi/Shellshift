const el=id=>document.getElementById(id);
const sim=new Simulation(), sector=el('sector');
let foundPass=false, loaded=false;
let outside=false,snapshot='',audio;
function tone(frequency){
  if(!audio || audio.state!=='running')return;
  const osc=audio.createOscillator(),gain=audio.createGain();
  osc.type='triangle';osc.frequency.value=frequency;
  gain.gain.setValueAtTime(.08,audio.currentTime);gain.gain.exponentialRampToValueAtTime(.001,audio.currentTime+.14);
  osc.connect(gain);gain.connect(audio.destination);osc.start();osc.stop(audio.currentTime+.15);
}
document.addEventListener('pointerdown',()=>{try{audio??=new AudioContext();audio.resume().catch(()=>{});}catch{}},{once:true});
function view(value){
  outside=value;el('world').hidden=!value;el('desk').hidden=value;if(value && !sector.hasAttribute('src'))sector.src='fte/index.html';
  syncSector();
  window.scrollTo(0,0);if(value)sector.focus();
}
document.querySelectorAll('.exit').forEach(b=>b.onclick=()=>view(true));
el('back').onclick=()=>view(false);
document.querySelectorAll('[data-focus]').forEach(b=>b.onclick=()=>{
  const panel=el(b.dataset.focus);panel.scrollIntoView({block:'center',behavior:'smooth'});
  panel.animate([{outline:'3px solid #efae51'},{outline:'3px solid transparent'}],700);
});
el('send').onclick=()=>{sim.request(el('route').value,performance.now());tone(450);};
el('deliver').onclick=()=>{sim.deliver(performance.now());tone(630);};
function syncSector(){
  if(!loaded)return;
  sector.contentWindow.postMessage({type:'sector-state',active:outside,pairs:sim.pairs,packet:sim.packet?Math.floor(sim.packet.progress*100):-1},'*');
}
window.addEventListener('message',e=>{
  if(e.source!==sector.contentWindow)return;
  if(e.data?.type==='sector-ready'){loaded=true;syncSector();}
  if(e.data?.type==='sector-exit')view(false);
  if(e.data?.type==='sector-pass')foundPass=true;
});
function frame(now){
  sim.tick(now);
  const p=sim.packet, phase=p?.state,mark=Math.floor((p?.progress||0)*100);
  const key=[phase,mark,sim.completed,sim.pairs,foundPass].join('/');
  if(key!==snapshot){
    snapshot=key;syncSector();
    let status='In attesa di una richiesta.';
    if(phase==='moving')status=mark<50?'Richiesta in transito nel tubo.':'Sigillo applicato · trasferimento in corso.';
    if(phase==='denied'){status='Clac. Mirror pubblico bloccato. Il Supervisor consente l’archivio interno.';tone(110);}
    if(phase==='received')status='Pagina 12 ricevuta. Il catalogo è pronto per la consegna.';
    if(sim.completed)status=sim.pairs===1?'Consegnato. Dal Gateway arriva un rumore…':'Task completata. Il Gateway ha creato il nodo 02.';
    el('status').textContent=status;
    el('signal').value=mark;
    el('archive').dataset.phase=phase||'idle';
    el('line').textContent=p?'PKT '+String(p.id).padStart(3,'0')+' / '+mark+'% · '+phase.toUpperCase():'NODO 01 ── IDLE';
    el('send').disabled=phase==='moving'||phase==='received';
    el('deliver').disabled=phase!=='received'||sim.completed;
    el('pages').textContent=phase==='received'?'11 ▪ 12 ▪ 13 / Catalogo completo':'11 ▪ ▪ 13 / Pagina 12 assente';
    el('task').textContent=(sim.completed?'✓ Task consegnata':'Task aperta · Pagina 12')+(foundPass?' · Pass del corriere ◆':'');
  }
  requestAnimationFrame(frame);
}
requestAnimationFrame(frame);
