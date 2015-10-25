module overpunch;

import std.stdio;
import std.string;
import std.algorithm.iteration;

import rbf.fieldtype;
import rbf.field;
import rbf.record;

static string posTable = makeTrans("{ABCDEFGHI}", "01234567890");
static string negTable = makeTrans("JKLMNOPQR", "123456789");

void overpunch(Record rec)
{
	// loop only on numerical fields
	//foreach (field; rec.filter!(f => f.fieldType.rootType == RootType.NUMERIC)) {
	foreach (field; rec) {

		// loop if not a numerical value
		if (field.fieldType.baseType == BaseType.string)
			continue;

		auto s = field.value;
		// found {ABCDEFGHI} in s: need to translate
		if (s.indexOfAny("{ABCDEFGHI}") != -1) {
			field.value = translate(s, posTable);
		}
		else if (s.indexOfAny("JKLMNOPQR") != -1) {
			field.value = translate(s, negTable);
			field.sign = -1;
		}
	}
}
