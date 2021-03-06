// 05.12.2010 15:20

Date.padded2 = function(hour) { padded2 = hour.toString(); if ((parseInt(hour) < 10) || (parseInt(hour) == null)) padded2="0" + padded2; return padded2; }
Date.prototype.getAMPMHour = function() { hour=Date.padded2(this.getHours()); return (hour == null) ? 00 : (hour > 24 ? hour - 24 : hour ) }
Date.prototype.getAMPM = function() { return (this.getHours() < 12) ? "" : ""; }

Date.prototype.toFormattedString = function(include_time){
  str = Date.padded2(this.getDate()) + "." + (this.getMonth() + 1) + "." + this.getFullYear();
  if (include_time) { hour=this.getHours(); str += " " + this.getAMPMHour() + ":" + this.getPaddedMinutes() }
  return str;
}

Date.parseFormattedString = function (string) {
  var regexp = '([0-9]{1,2})\.([0-9]{1,2})\.([0-9]{4})( ([0-9]{1,2}):([0-9]{2})? *)?';
  var d = string.match(new RegExp(regexp, "i"));
  if (d==null) return Date.parse(string); // at least give javascript a crack at it.
  var offset = 0;
  var date = new Date(d[3], 0, 1);
  if (d[2]) { date.setMonth(d[2] - 1); }
  if (d[1]) { date.setDate(d[1]); }
  if (d[4]) {
    date.setHours(parseInt(d[5], 10));    
  }
  if (d[8]) { date.setMinutes(d[6]); }
  return date;
}
Date.first_day_of_week = 1;