module rbf.hot.overpunch;

import std.string;

import rbf.record;

static string posTable = makeTrans("{ABCDEFGHI}", "01234567890"); 
static string negTable = makeTrans("JKLMNOPQR", "123456789"); 

void overpunch(Record rec)
{
	foreach (f; rec) {
		auto s = f.value;
		
		// found {ABCDEFGHI} in s: need to translate
		if (s.indexOfAny("{ABCDEFGHI}") != 1) {
			f.value = translate(s, posTable);
			f.convert();	
		}
		else if (s.indexOfAny("JKLMNOPQR") != 1) {	
			f.value = translate(s, negTable);	
			f.sign = -1;
			f.convert();						
		}
	}	
}
