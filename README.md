# Shellshift

Il gioco corrente si apre da Godot con `godot --path godot`. Il registro consente di scegliere Ada, Nico o Lea. Esc salta il prologo 3D e avvia il turno 2D. La [storia e il documento di continuità](docs/plot.md) raccolgono personaggi, missioni giocabili e capitoli previsti.

Per la prossima lettura d’autore, [Il posto al finestrino](docs/copione-di-lavoro.md) raccoglie la proposta per il primo turno, la prospettiva dell’agente e gli ingressi di scena. Il [copione di montaggio](docs/screenplay.md) segue il film attualmente in Godot.

Il capitolo attraversa il film iniziale, il turno sul desktop, la mappa di manutenzione e il filesystem 3D. Nel filesystem si cammina con WASD, si guarda con il mouse o con le frecce destra e sinistra, si usa una postazione con E o Invio. Esc apre la pausa. Per provare direttamente il primo spazio esplorabile esegui `godot --path godot res://shift/filesystem.tscn`.

Il prologo dura 3 minuti e 13 secondi. Comincia con Rosa e sua madre in fila allo sportello comunale. Per vederlo subito con il fascicolo di Ada esegui `godot --path godot -- --prologo`. La scena dei programmatori si può aprire da sola in Godot con `godot/office/venerdi.tscn`. F6 riproduce la sua animazione.

Nel [provino di Ada e Mara](previews/provino-ada-mara.mp4), Mara esce dal reparto, sistema la sciarpa di Ada e la abbraccia. È un provino di casting separato dal prologo, con due interpreti della [libreria Rocketbox](godot/casting/SOURCES.md). La [scena Godot](godot/casting/hospital.tscn) si riproduce con F6. Per registrare di nuovo i 15 secondi con la musica originale esegui `python3 tools/render_casting.py` dalla radice del progetto con Godot e FFmpeg disponibili.

## Prototipo browser · Settore Nero

Avventura single-player per browser. Nella cartella estratta, esegui `python3 serve.py` e apri http://127.0.0.1:8000. Il settore 3D richiede WebGL. Il pacchetto contiene il motore e tutti i dati della missione.

## Missione

Dal desktop della sandbox recupera la pagina 12. Richiedi il file, apri lo sportello per seguire il pacchetto nel settore e consegna il catalogo dal desktop. Otto secondi dopo la consegna il Gateway crea la seconda coppia. Nel settore puoi anche cercare il pass del corriere dietro la sandbox.

Usa W/S per avanzare e arretrare, A/D per spostarti di lato e le frecce sinistra/destra per girarti. Spazio per saltare, Esc per tornare al desktop. Su touchscreen usa i pulsanti a schermo.

## Motore e dati

Il desktop HTML e la missione in sim.js comunicano con FTEQW via fte/launch.js. Nel settore, geometria BSP, collisioni, lightmap, personaggi MDL e logica QuakeC sono caricati dal motore. Le richieste di rete e i permessi rappresentati nella missione sono simulati localmente.

Il runtime WebAssembly proviene dalla distribuzione ufficiale https://fte.triptohell.info/moodles/web/. I sorgenti del motore sono disponibili su https://sourceforge.net/p/fteqw/code/HEAD/tree/trunk/. Licenza inclusa in fte/engine/COPYING. Per il corriere, adattato al formato MDL, e le texture vedi assets/CREDITS.md.

fte/src contiene mappa, generatori degli asset e sorgenti QuakeC. Per rigenerare i dati servono Python con Pillow, NumPy e SciPy, gli strumenti ericw-tools (qbsp, vis, light) e FTEQCC. Il pacchetto di gioco già compilato si trova in fte/game/sector.pk3.
