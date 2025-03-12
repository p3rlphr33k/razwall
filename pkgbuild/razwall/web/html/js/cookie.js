function getCookie(name) {
var nameEQ = name + "=";
	  var ca = document.cookie.split(';');
	  for(var i=0;i < ca.length;i++) {
	    var c = ca[i];
	    while (c.charAt(0)==' ') c = c.substring(1,c.length);
	    if (c.indexOf(nameEQ) == 0)
		{ 
		window.open('/cgi-bin/core.pl?do=home&session=' + c.substring(nameEQ.length,c.length) ,'_top');
		}
	  }
	  return null;
	}
	
function createCookie(name, value, days)
{
    var expires = '',
    date = new Date();
    if (days)
	{
	date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
        expires = '; expires=' + date.toGMTString();
        }
    document.cookie = name + '=' + value + expires + '; path=/';
}

function readCookie(name)
{
    var nameEQ = name + '=',
    allCookies = document.cookie.split(';'),i,cookie;
    for (i = 0; i < allCookies.length; i += 1) {
    cookie = allCookies[i];
    while (cookie.charAt(0) === ' ') {
    cookie = cookie.substring(1, cookie.length);
    }
    if (cookie.indexOf(nameEQ) === 0) {
    return cookie.substring(nameEQ.length, cookie.length);
    }
    }
    return null;
}

function eraseCookie(name) {
    createCookie(name, '', -1);
}

