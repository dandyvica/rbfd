module rbf.errormsg;


immutable MSG001 = "error: element name %s is not in container %s";
immutable MSG002 = "warning: field %s is not matching expected pattern <%s>";
immutable MSG003 = "name=<%s>, description=<%s>, length=<%u>, type=<%s>, lower/upperBound=<%u:%u>, rawValue=<%s>, value=<%s>, offset=<%s>, index=<%s>";
immutable MSG004 = "error: settings file <%s> not found";
immutable MSG005 = "error: element %s, index %d is out of bounds";
immutable MSG006 = "error: cannot call get method with index %d without allowing duplicated";
immutable MSG007 = "error: lower index %d is out of bounds, upper bound = %d";
immutable MSG008 = "error: upper index %d is out of bounds, upper bound = %d";
immutable MSG009 = "error: lower index %d is higher than upper index %d";
