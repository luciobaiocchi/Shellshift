from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import sys
src=Path(__file__).resolve().parent
base=Path(sys.argv[1])
with ZipFile(src.parent/'game/sector.pk3','w',compression=ZIP_DEFLATED) as z:
    for name in ('gfx/palette.lmp','gfx/colormap.lmp','maps/void.bsp','progs/courier.mdl','progs/signal.mdl','qwprogs.dat','sector.cfg'):
        z.write(base/name,name)
