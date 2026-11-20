extends RefCounted
## An empty cue leaves the picture and score alone until the next entrance.
# Set IDs stay fixed so previews and camera takes can select the same physical set.
const SHOT_ORDER := [10,11,0,1,2,3,4,5,6,12,7,8,9]
const YEARS := ["2026","2026","2027","2029","2030","2032","2041","2053","2053","SHIFT 01","2024","2026","2047"]
const SECONDS := [12,11,16,15,15,15,14,13,12,10,22,20,18]
const NAMES := ["Ada","Nico","Lea"]
const BADGES := ["H-0317","H-0442","H-0528"]
const MEMORIES := ["Dome notebook","Valley radio","Witness bench"]
const OFFICE_CUES := [
	[0.0,""],
	[2.8,"“It ran all forty-eight over lunch.”"],
	[6.2,"“Is it really only four?”"],
	[9.0,"“Come on. Bring your coat.”"]
]
const ORDERS := ["3 SLIDES","RESTORE ROSTER","CERTIFY REPORT"]
const ARCHIVE_SOURCES := {
	2:"Aster · paid airtime", 3:"Mara and Ada · hospital garden", 4:"Lea · safety review",
	6:"Ivo · signal box", 7:"Ren · transfer desk",
	10:"Rosa · after work", 11:"Rosa · benefits office", 12:"Rosa · change of address"
}

const ARCHIVE := {
	10:[[0.0,""],
	    [1.4,"My shift ended at six. Mum had been in line since two."],
	    [5.7,"She gave me the rent ticket and kept the one for food."],
	    [10.2,"“Rosa, how far can you walk in those shoes?”"],
	    [14.0,"The clerk found Mum a chair. We heard our bus go."],
	    [19.0,""]],
	11:[[0.0,"The council let an Aster agent try the claims still waiting."],
	    [4.9,"It found six weeks of rent money the office owed Mum."],
	    [8.7,"“Keep the pears, Mum. They’re covered.”"],
	    [11.5,"They asked if it could do next month. I signed."],
	    [15.6,"“Window seat, Mum?”"],
	    [18.1,""]],
	12:[[0.0,"Mum moved in with me. Her food still went to the old flat."],
	    [4.9,"Our council hired Aster for less than the clerks’ wages. The clerks went."],
	    [10.2,"I gave both addresses and asked to speak to someone."],
	    [14.2,"The old flat got our pears for another week."]],
	2:[[0.0,"Aster bought the last minute before the evening news."],
	   [4.0,"“A cure for every illness. An end to cancer.”"],
	   [8.0,"“An end to hunger and inequality.”"],
	   [11.3,"“A basic income for everyone. Think what you could do.”"]],
	3:[[0.0,""],
	   [0.8,"Mum was coming home. The treatment worked."],
	   [3.6,"“Bought a return this time.”"],
	   [6.0,"“Here, Ada. Your collar.”"],
	   [8.1,"Same thumb under the fold."],
	   [10.3,""]],
	4:[[0.0,"I checked the proofs. We had been stuck for nine years."],
	   [4.9,"An agent solved it overnight. It took us six months to check."],
	   [10.0,"By then its successor had designed a better one. I still had the stamp."]],
	6:[[0.0,"The river took the valley road again. Three trains were still out."],
	   [5.1,"I gave dispatch the switches. Everybody got home."],
	   [9.0,"Next flood, my lever was stiff. Nobody needed me to pull it."]],
	7:[[0.0,"Aster’s robots ran the city. By law, appeals still needed a human signature."],
	   [5.3,"They turned us into neural networks and gave us the appeals to sign."],
	   [10.0,"I held the gate. Then they called me."]]
}

const ROUTES := [
	{
		0:[[0.0,""],
		   [2.8,"“It ran all forty-eight over lunch.”"],
		   [5.9,"“Is it really only four?”"],
		   [9.0,"“Go, Ada. I’ll lock up.”"]],
		1:[[0.0,"Mum brought two cups. I kept our place in the red book."],
		   [4.8,"“See that third dot, Mum? It was over here last Thursday.”"],
		   [9.45,"“Show me.”"]],
		5:[[0.0,""],
		   [2.1,"After Mum died, I still poured two cups."],
		   [6.2,"I asked it to take one Thursday. I left the switch on."],
		   [11.0,"Downstairs, I kept playing the Thursday with her voice on it."]],
		8:[[0.0,"“Will I get the notebook back?”"],
		   [3.2,"The antimatter gun flashed. I heard the cover hit the floor."],
		   [8.3,"I was inside the computer. I still reached for it."]],
		9:[[0.0,"They put my telescope on the desktop."],
		   [3.2,"Three slides about the third point. Seven minutes."],
		   [7.4,"Somebody kept page twelve."]]
	},
	{
		0:[[0.0,""],
		   [2.8,"Ada checked twice. The agent had run all forty-eight."],
		   [5.9,"“Is it really only four?”"],
		   [9.0,"Still time to fix Tom’s radio before dark."]],
		1:[[0.0,"Three village relays on the bench. I pulled the middle cable."],
		   [5.15,"The bridge was under water. My brother said, “Still here, Nic.”"],
		   [9.1,"So the line held."]],
		5:[[0.0,""],
		   [1.8,"On flood nights I slept with my hand on the radio."],
		   [6.0,"Tom called. I turned the line over to the agent."],
		   [10.4,"In the simulation the bridge was dry. I slept till noon."]],
		8:[[0.0,"I’d left the relay board in my coat."],
		   [3.4,"The antimatter gun flashed. The board bounced twice."],
		   [7.8,"I heard both knocks from inside the computer."]],
		9:[[0.0,"Thursday’s shift is gone. They want me to put it back."],
		   [4.7,"They’ve shut the outside line."],
		   [7.75,"I try the local copy."]]
	},
	{
		0:[[0.0,""],
		   [2.8,"I heard Ada through the wall. “It ran all forty-eight.”"],
		   [5.9,"Then Nico. “Is it really only four?”"],
		   [9.0,"Jo went to get our coats."]],
		1:[[0.0,"Jo had the chair on my left. I covered one lamp."],
		   [4.9,"I asked if she’d sign. “Move your thumb first.”"],
		   [9.0,"I kept her answer."]],
		5:[[0.0,""],
		   [1.8,"Jo’s chair was empty. The night bell kept going."],
		   [6.0,"I let it sign for Jo that night. The bell stopped mid-ring."],
		   [11.6,"In the morning, both marks looked like mine."]],
		8:[[0.0,"My transfer form already had two signatures."],
		   [3.7,"The antimatter gun flashed. My stamp fell face down."],
		   [8.0,"Inside the computer, I could still feel its handle."]],
		9:[[0.0,"Page twelve shows the star moving. The report says it stood still."],
		   [5.3,"Someone has signed my name. They give me seven minutes to agree."]]
	}
]

static func cues(profile: int, shot: int) -> Array:
	if ROUTES[profile].has(shot):
		return ROUTES[profile][shot]
	return ARCHIVE[shot]

static func source(profile: int, shot: int, _elapsed: float) -> String:
	if ARCHIVE_SOURCES.has(shot):
		return ARCHIVE_SOURCES[shot]
	match shot:
		0: return NAMES[profile] + " · Friday afternoon"
		1,5: return NAMES[profile]+" · "+MEMORIES[profile]
		8: return NAMES[profile]+" · transfer record"
		_: return "Terminal "+BADGES[profile]
