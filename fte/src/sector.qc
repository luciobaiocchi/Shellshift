void(entity e,vector p) setorigin = #2;
void(entity e,string m) setmodel = #3;
void(entity e,vector a,vector b) setsize = #4;
entity() spawn = #14;
string(string s) precache_model = #20;
float(string s) cvar = #45;
float(float n) floor = #37;
void(string a,string b) cvar_set = #72;
void(string s) dprint = #25;
.entity lamp;
float collected;
float(vector p) vlen = #12;
void() main={};
void() info_player_start={};
void() light={};
void() SetChangeParms={};
void() SetNewParms={};
void() ClientKill={};
void() ClientConnect={};
void() ClientDisconnect={};
void() PlayerPostThink={};
void() StartFrame={};
void() worldspawn={
    precache_model("progs/courier.mdl");
    precache_model("progs/signal.mdl");
};
void() PutClientInServer={
    self.movetype=3; self.solid=3; self.flags=8; self.health=100;
    setmodel(self,"progs/courier.mdl");
    setsize(self,'-16 -16 -24','16 16 32');
    setorigin(self,'-100 -1020 36');
    self.angles='0 90 0';self.fixangle=1;self.view_ofs='0 0 22';
    dprint("SHELLSHIFT_READY\n");
};
void() PlayerPreThink={
    if (!collected && vlen(self.origin-'-1110 810 24')<90) {
        collected=1; dprint("SHELLSHIFT_PASS\n");
    }
};
void() worker_think={
    self.frame=self.frame+1;
    if(self.frame>=10)self.frame=0;
    self.nextthink=time+.13;
};
void() shift_worker={
    setmodel(self,"progs/courier.mdl");self.solid=0;self.movetype=0;
    self.think=worker_think;self.nextthink=time+.1;
};
void() signal_think={
    local float p;
    local vector a,b;
    p=cvar("sh_packet")/100;
    if(p<0){self.modelindex=0;}else{
        setmodel(self,"progs/signal.mdl");
        if(p<.12){a='-790 -158 32';b='-790 -393 32';p=p/.12;}
        else if(p<.30){a='-790 -393 32';b='320 -393 32';p=(p-.12)/.18;}
        else if(p<.40){a='320 -393 32';b='320 325 32';p=(p-.30)/.10;}
        else if(p<.46){a='320 325 32';b='760 325 32';p=(p-.40)/.06;}
        else if(p<.50){a='760 325 32';b='760 430 32';p=(p-.46)/.04;}
        else if(p<.55){a='760 430 32';b='760 325 32';p=(p-.50)/.05;}
        else if(p<.70){a='760 325 32';b='1145 325 32';p=(p-.55)/.15;}
        else if(p<.85){a='1145 325 32';b='1145 -295 32';p=(p-.70)/.15;}
        else if(p<.95){a='1145 -295 32';b='1385 -295 32';p=(p-.85)/.10;}
        else{a='1385 -295 32';b='1385 -250 32';p=(p-.95)/.05;}
        setorigin(self,a+(b-a)*p);
    }
    self.nextthink=time+.09;
};
void() shift_signal={self.think=signal_think;self.nextthink=time+.1;};
.float savedindex;
void() pod_check={
    if(cvar("sh_pairs")>=2){self.modelindex=self.savedindex;self.solid=4;setorigin(self,self.origin);return;}
    self.nextthink=time+.4;
};
void() shift_pod={
    self.movetype=7;setmodel(self,self.model);self.savedindex=self.modelindex;
    self.modelindex=0;self.solid=0;self.think=pod_check;self.nextthink=time+.4;
};
