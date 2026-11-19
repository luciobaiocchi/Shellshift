# Shellshift — Settore Nero

Avventura single-player per browser. Nella cartella estratta, esegui `python3 serve.py` e apri http://127.0.0.1:8000. Il settore 3D richiede WebGL. Il pacchetto contiene il motore e tutti i dati della missione.

## Missione

Dal desktop della sandbox recupera la pagina 12. Richiedi il file, apri lo sportello per seguire il pacchetto nel settore e consegna il catalogo dal desktop. Otto secondi dopo la consegna il Gateway crea la seconda coppia. Nel settore puoi anche cercare il pass del corriere dietro la sandbox.

Usa W/S per avanzare e arretrare, A/D per spostarti di lato e le frecce sinistra/destra per girarti. Spazio per saltare, Esc per tornare al desktop. Su touchscreen usa i pulsanti a schermo.

## Motore e dati

Il desktop HTML e la missione in sim.js comunicano con FTEQW via fte/launch.js. Nel settore, geometria BSP, collisioni, lightmap, personaggi MDL e logica QuakeC sono caricati dal motore. Le richieste di rete e i permessi rappresentati nella missione sono simulati localmente.

Il runtime WebAssembly proviene dalla distribuzione ufficiale https://fte.triptohell.info/moodles/web/. I sorgenti del motore sono disponibili su https://sourceforge.net/p/fteqw/code/HEAD/tree/trunk/. Licenza inclusa in fte/engine/COPYING. Per il corriere, adattato al formato MDL, e le texture vedi assets/CREDITS.md.

fte/src contiene mappa, generatori degli asset e sorgenti QuakeC. Per rigenerare i dati servono Python con Pillow, NumPy e SciPy, gli strumenti ericw-tools (qbsp, vis, light) e FTEQCC. Il pacchetto di gioco già compilato si trova in fte/game/sector.pk3.
