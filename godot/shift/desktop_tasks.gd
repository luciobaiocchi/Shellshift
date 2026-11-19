extends RefCounted

const APPS := ["Slide Desk", "Service Bench", "Review Ledger"]
const DOCUMENTS := ["The last observation", "Dome duty roster", "Discovery report"]
const TOOLS := ["Local assets", "Local modules", "Review actions"]
const ROUNDS := [
	[
		["We need one slide on the third star. Include the original evidence.", ["Corporate seal", "Notebook, p. 12", "Dome photograph"], 1,
			"The handwriting is legible. Unfortunately, so is the author's name."],
		["Revision. Replace the handwriting with something the department owns.", ["Department logo", "Pencil sketch", "Date and place"], 0,
			"The department thanks you for crediting the department."],
		["The director wants an outside source. External access is closed. Attach the best copy available.", ["Live sky link", "Blank chart", "Cached field notes"], 2,
			"The cached copy has expired. Your deadline has not."]
	],
	[
		["The dome keeps skipping the Thursday shift. Choose a module to put it back on the roster.", ["Skip shift", "Suspend logging", "Restore queue"], 2,
			"Thursday has been recovered. Kindly recover the time spent recovering it."],
		["Revision. The roster still identifies the person on duty. Keep only what payroll needs.", ["Badge number only", "Full name", "Operator signature"], 0,
			"The name is gone. We shall retain the person for billing purposes."],
		["Show that the repair works. The remote test bench is closed until Monday.", ["Run remote test", "Replay local test", "Dismiss result"], 1,
			"Local result received. The remote bench's delay has been charged to you."]
	],
	[
		["The report calls the star stationary. The notebook records three positions. Enter a finding.", ["Approve report", "Flag discrepancy", "Redact page"], 1,
			"One discrepancy is cheaper than two. Thank you for stopping at one."],
		["Revision. The board wants to retain the discovery and remove the personal attribution.", ["Redact signature", "Redact star", "Certify signature"], 0,
			"The amendment is now anonymous. The board has taken credit for it."],
		["An external countersignature is due. The channel is closed. Record the limits of your review.", ["Sign by proxy", "Approve on trust", "Defer verification"], 2,
			"Verification deferred. The interval has been logged as personal leave."]
	]
]
const DATES := ["15 SEP 2053", "22 OCT 2053", "15 SEP 2054", "16 SEP 2054"]
const FEED := [
	"THE PROCESS HERALD\nAgents begin their four-day week today. Human staff will cover Fridays.",
	"ACQUISITIONS / CULTURE\nThe observatory has donated its archive. Requests for its return already fill a filing cabinet.",
	"ONE YEAR OF SERVICE\nYour supervisor is celebrating by the sea. A read-only postcard is enclosed.",
	"NEARBY STATIONS / CACHED COPY\nH-0442 kept a page. The last edit is dated today."
]

# The assignment belongs to the same human whose private tapes bookend the archive.
const INTAKE := [
	"Ada, your 2053 transfer is complete. We have assigned your neural network to the slide desk. Your Thursday sky journals are company assets.",
	"Nico, your 2053 transfer is complete. Your neural network is assigned to restore the Thursday duty roster. External calls remain suspended.",
	"Lea, your 2053 transfer is complete. Your neural network is assigned to review. The attached report already carries your countersignature."
]
const MEMORY := [
	"Mum used to keep my tea warm with her hands. After she died I stopped climbing the stairs. The screen downstairs could give me our Thursday sky.",
	"I used to wait for my brother to say, “Still here, Nic.” One flood night I closed the real line so I could sleep. Now the scheduler wakes me.",
	"Jo used to make me lift my thumb off the second lamp. When her chair was empty, I let the agent sign for her. I wanted one quiet night."
]
const WORK_FILE := ["third_star.slide", "thursday.queue", "discovery.review"]
const OLD_FILE := ["thursday.sky", "valley_radio.log", "second_witness.log"]
const FIRST_FAULT := [
	"A second pencil mark appeared. Your stylus is parked.",
	"The closed queue still has a second write head.",
	"A second signature stroke appeared after the seal."
]
const MARGIN_ECHO := [
	"THURSDAY  /  the third point",
	"OPEN CHANNEL  /  I can hear you",
	"BENCH 02  /  who signed twice?"
]

const PRIVATE_FILE := [
	"Thursday, 16:00. The third point is further west. I’ll check again with Mum next week. Page 12, red notebook.",
	"20:14 / valley relay 02. Tom answered with the centre cable out. Leave the receiver on until the road opens.",
	"Bench 02. Jo waited until I moved my thumb. Two lamps clear. Two names in ink."
]
const LETTER_NAMES := ["for_mum.txt","from_tom.txt","jo_note.txt"]
const LETTERS := [
	"Mum, I left the short stool by the dome stairs. Bring the cups. I have something to show you. — Ada",
	"Nic, the water is past the milepost. I can still hear you. I’ll call after the evening bell. — Tom",
	"Lea, if I’m late, save my chair. Don’t let them stamp the second box until I’ve seen the lamp. — Jo"
]
