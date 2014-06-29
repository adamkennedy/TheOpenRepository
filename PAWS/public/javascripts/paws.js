
var recents = new Hash();
var current_document;

function setActiveStyleSheet(title) {
   var i, a, main;
   for(i=0; (a = document.getElementsByTagName("link")[i]); i++) {
     if(a.getAttribute("rel").indexOf("style") != -1
        && a.getAttribute("title")) {
       a.disabled = true;
       if(a.getAttribute("title") == title) a.disabled = false;
     }
   }
   createCookie("style",title,365)
}

function getActiveStyleSheet() {
 var i, a;
 for(i=0; (a = document.getElementsByTagName("link")[i]); i++) {
  if(a.getAttribute("rel").indexOf("style") != -1
  && a.getAttribute("title")
  && !a.disabled) return a.getAttribute("title");
  }
  return null;
}

function createCookie(name,value,days) {
  if (days) {
    var date = new Date();
    date.setTime(date.getTime()+(days*24*60*60*1000));
    var expires = "; expires="+date.toGMTString();
  }
  else expires = "";
  document.cookie = name+"="+value+expires+"; path=/";
}

function readCookie(name) {
  var nameEQ = name + "=";
  var ca = document.cookie.split(';');
  for(var i=0;i < ca.length;i++) {
    var c = ca[i];
    while (c.charAt(0)==' ') c = c.substring(1,c.length);
    if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
  }
  return null;
}

function getPreferredStyleSheet() {
  var i, a;
  for(i=0; (a = document.getElementsByTagName("link")[i]); i++) {
    if(a.getAttribute("rel").indexOf("style") != -1
       && a.getAttribute("rel").indexOf("alt") == -1
       && a.getAttribute("title")
       ) return a.getAttribute("title");
  }
  return null;
}

window.onload = function(e) {
  var cookie = readCookie("style");
  var title = cookie ? cookie : getPreferredStyleSheet();
  setActiveStyleSheet(title);
}


function refresh_document() {
    display_document(current_document);
}

function display_document(name) {
    
    var f_overlay = $F('overlay');
    var f_view = $F('view');
    var f_sort = $F('sort');
    
    new Ajax.Updater(
    'pod_content','/search',
    { 
        parameters: { terms: name, overlay: f_overlay, sort: f_sort, view: f_view },
        onSuccess: function(response) {
            recents.set(name, '1');
            current_document = name;
            var el = update_recents(name);
            el.setStyle({
                backgroundColor: "#ffff99"
            });
            new Effect.Shake(el,{duration: 0.2, distance: 4});
            
            new Ajax.Updater(
                'menu','/menu',
                {parameters: {terms: name}}
                );
            new Ajax.Updater(
                'doc_links','/links',
                {parameters: {terms: name}}
                );
                
        }
    }
    );
}

function update_recents(name) { // returns the element created for "name" if possible
    var out = null;
    $(recent_searches).childElements().each(function(e) { e.remove() });
    recents.keys().sort().each( function(k) {
        var li = new Element('li');
        var a = new Element("a",{ href: "#", onClick: "display_document('"+k+"')" });
        var x = new Element("a",{ href: "#", 'onClick': "kill_recent('"+k+"')", 'class': "close"});
        a.appendChild(document.createTextNode(k));
        x.appendChild(document.createTextNode("•"));

        li.appendChild(x);
        li.appendChild(a);

        $(recent_searches).insert(
            {bottom: li});
        if(name == k) {
            out = li;
        }
    });
    return out;
}

function kill_recent(k) {
    var el = update_recents(k);
    recents.unset(k);
    
    new Effect.DropOut(el,{
        afterFinish: function(){ update_recents() }
    });
}

PAWS_FastSearch = Class.create();
PAWS_FastSearch.prototype = {
    initialize: function(field,request_path) {
        var obj = this;
        obj.s_field = field;
        obj.s_path = request_path;
        obj.initializeElements();
    },
    initializeElements: function() {
        var fs_field = $(this.s_field);
        var div_name = "paws_fsearch";
        var obj = this;
        
        this.prev_value = this.terms();
        this.has_results = false;
        this.px = new PeriodicalExecuter(obj.fs_load_praps.bind(obj),0.5);
        this.ajax_active = false;
        this.key_select = false;
        
        var div = $(div_name);
        if (div) {
            fs_field.observe("focus", obj.fs_focus.bind(obj));
            fs_field.observe("blur", obj.fs_blur.bind(obj));
            //fs_field.observe("keydown", obj.fs_select.bind(obj));
        }
  },
  fs_div: function() {
      var div_name = "paws_fsearch";
      return $(div_name);
  },
  fs_load_praps: function() {
      if(this.prev_value != this.terms()) {
          if(!this.ajax_active) {
              this.fs_load();
          }
      }
  },
  fs_focus: function() {
      if( this.has_results ) {
          this.fs_show()
      }
  },
  fs_blur: function() {
      this.fs_hide();
  },
  fs_hide: function() {
      var obj = this;
      var f = function() {
          obj.fs_div().hide();
      }.delay(0.2);  
  },
  fs_show: function() {
      this.fs_div().show();
  },
  fs_load: function() {
      var div = this.fs_div();
      var path = this.s_path;
      var obj = this;
      var tval = this.terms();
      this.ajax_active = true;
      new Ajax.Updater(div,path, {
          parameters: { "terms" : tval },
          evalScripts: false,
          method: "GET",
          onComplete: function(transport) {
              var response_divs = div.select("div.fs_section");
              var section_count = response_divs.length;
              div.setStyle({width: '' + (300 * section_count) + 'px', position: 'absolute'})
              obj.ajax_active = false;
              
              var total_lines = div.select("div.result_line");
              if(total_lines.length == 0) {
                  obj.fs_hide();
                  return true;
              } else {
                  obj.has_results = true;
                  obj.fs_div().show();
                  obj.prev_value = tval;
              }
          }
      }
      );
  },
  terms: function() {
      return $(this.s_field).getValue();
  }
}