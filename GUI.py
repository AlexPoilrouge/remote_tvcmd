#!/bin/python3

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GObject, GLib

import sys, os
import time
import threading
import fileinput
from enum import Enum
import json
import re

HERE_PATH= os.path.abspath(os.path.dirname(sys.argv[0]))

def printForPipe(arg):
    print( arg )
    sys.stdout.flush()
    time.sleep(0.05)

def printOnErr(arg) :
    sys.stderr.write( arg )
    sys.stderr.flush()
    time.sleep(0.05)



class MyGUI(GObject.GObject) :
    class Handler:
        def __init__(self, parent, objects={}):
            self._parent= parent
            self._objects= objects

        def onDestroy(self, *args):
            printForPipe("QUIT")
            time.sleep(1)
            Gtk.main_quit()

        def onFilterToggled(self, *args):
            obj= args[0]
            if obj.get_active() :
                for id in ['NewToggle', 'UpcomingToggle', 'SeenToggle', 'AcquiredToggle', 'AllToggle', 'IgnoreToggle'] :
                    if self._objects[id] != obj :
                        self._objects[id].set_active(False)

                gladeName= Gtk.Buildable.get_name(args[0])
                if gladeName == "NewToggle" :
                    self._parent._onFilter= MyGUI.FILTER.NEW
                elif gladeName == "UpcomingToggle" :
                    self._parent._onFilter= MyGUI.FILTER.UPCOMING
                elif gladeName == "SeenToggle" :
                    self._parent._onFilter= MyGUI.FILTER.SEEN
                elif gladeName == "AcquiredToggle" :
                    self._parent._onFilter= MyGUI.FILTER.ACQUIRED
                elif gladeName == "IgnoreToggle" :
                    self._parent._onFilter= MyGUI.FILTER.IGNORED
                else:
                    self._parent._onFilter= MyGUI.FILTER.ALL
                self._parent._filterSearch()

        def onShowEntered(self, *args):
            self._parent._filterSearch()

        def onDeleteShowText(self, *args):
            self._objects["ShowSearchEntry"].set_text('')
            self._parent._filterSearch()


        def onShowAdd(self, *args):
            show= self._objects["ShowSearchEntry"].get_text().lower().replace(' ','_').replace('\'','').replace('\:','')
            if show:
                printForPipe("REQUEST TVCMD ADD_SHOW "+show)

        def onToolSetNew(self, *args):
            self._parent.change_episode_selection_tag("new")

        def onToolSetSee(self, *args):
            self._parent.change_episode_selection_tag("see")

        def onToolSetAcquire(self, *args):
            self._parent.change_episode_selection_tag("acquire")

        def onToolSetIgnore(self, *args):
            self._parent.change_episode_selection_tag("ignore")

        def newTreeSelection(self, *args):
            self._parent.check_selection()

        def onDeleteSelectedShow(self, *args):
            self._parent.selected_show_delete()

        




    class FILTER(Enum):
        ALL=0
        NEW=1
        UPCOMING=2
        SEEN=3
        ACQUIRED=4
        IGNORED=5



    def __init__(self, gladFile):
        GObject.GObject.__init__(self)
        self.builder= Gtk.Builder()
        self.builder.add_from_file(gladFile)
        self.objects= {}

        self._onFilter= MyGUI.FILTER.ALL

        self._url= None
        
        for name in ['myWindow','Stack','ShowsPage',
                    'ErrorDialog', 'ValidDialog',
                    'NewToggle', 'UpcomingToggle', 'SeenToggle', 'AcquiredToggle', 'AllToggle', 'IgnoreToggle',
                    'ShowSearchEntry',
                    'ShowsTreeView', 'ShowsTreeStore', 'ShowTreeSelection',
                    'DeleteShowToolButton'] :
            self.objects[name]= self.builder.get_object(name)

        self._handler= MyGUI.Handler(self, self.objects)
        self.builder.connect_signals(self._handler)

        self.objects['AllToggle'].set_active(True)


    def show(self):
        if "myWindow" in self.objects and self.objects["myWindow"] :
            self.objects["myWindow"].show_all()

    def onConnect(self):
        self.objects['Stack'].set_visible_child(self.objects['ShowsPage'])
        self.objects['ConnectBtn'].set_label("gtk-disconnect")
        self.objects['EntryLogin'].set_sensitive(True)
        self.objects['EntryPass'].set_sensitive(True)
        self.objects['ConnectBtn'].set_sensitive(True)
        self._filterSearch()

    def onConnectCancel(self):
        self.objects['Stack'].set_visible_child(self.objects['WaitConnectLabel'])
        self.objects['ConnectBtn'].set_label("gtk-connect")
        self.objects['EntryLogin'].set_sensitive(True)
        self.objects['EntryPass'].set_sensitive(True)
        self.objects['ConnectBtn'].set_sensitive(True)

    def _dialog(self, dialogID, status, info=None):
        dial= self.objects[dialogID]

        dial.set_markup(status)
        if info:
            dial.format_secondary_text(info)

        response = dial.run()

        dial.hide()

    def errorDialog(self, status, info=None):
        self._dialog("ErrorDialog", status, info)

    def validDialog(self, status, info=None):
        self._dialog("ValidDialog", status, info)

    def _filterSearch(self):
        txt= self.objects["ShowSearchEntry"].get_text()
        txt= ('*'+txt+'*') if txt else ''

        if self._onFilter == MyGUI.FILTER.ALL :
            printForPipe("REQUEST TVCMD COMMAND ls -sna "+txt)
        elif self._onFilter == MyGUI.FILTER.NEW :
            printForPipe("REQUEST TVCMD COMMAND ls -n "+txt)
        elif self._onFilter == MyGUI.FILTER.UPCOMING :
            printForPipe("REQUEST TVCMD COMMAND ls -f "+txt)
        elif self._onFilter == MyGUI.FILTER.SEEN :
            printForPipe("REQUEST TVCMD COMMAND ls -s "+txt)
        elif self._onFilter == MyGUI.FILTER.ACQUIRED:
            printForPipe("REQUEST TVCMD COMMAND ls -a "+txt)
        elif self._onFilter == MyGUI.FILTER.IGNORED:
            printForPipe("REQUEST TVCMD COMMAND ls -i "+txt)

    def _processShowDB(self, show_db):
        treeStore= self.objects['ShowsTreeStore']
        
        for show in show_db.keys() :
            showNode= treeStore.append(None,(show,None,None,None,None,None))
            for episode in show_db[show] :
                treeStore.append(showNode,(None,episode[0],episode[1],episode[2],episode[3],episode[4],))

    def processJSONAnswer(self, data):
        obj= json.loads(data)
        db= {}
        if obj :
            if ("invoked" in obj) :
                if (re.match("^\s*COMMAND\s+(ls)(\s+|(\s\S+))*$", obj['invoked'])) :
                    if 'line_count' in obj :
                        self.objects['ShowsTreeStore'].clear()
                        l_count= obj['line_count']
                        for i_l in range(1, (l_count+1)):
                            line= obj["line"+str(i_l)]
                            m= re.match("^\s*(\S+)\.s([0-9]{2})e([0-9]{2})\s+\:\s+\[\s+(\S+)\s+\]\s+\[\s+([0-9]{4}\-[0-9]{2}\-[0-9]{2})\s+\]\s\[\s+(.*)\s+\].*$",
                                        line)
                            if m:
                                m= m.groups()
                                show= m[0]
                                #( season, episode, tag, date, name)
                                ep= ((int(m[1])), (int(m[2])), m[3], m[4], m[5])
                                if not show in db:
                                    db[show]= []
                                db[show].append(ep)
                else:
                    res= re.match("^\s*ADD_SHOW\s+(\S+)\s*$", obj['invoked'])
                    if res :
                        added_show= res.groups()[0]
                        l_count= obj['line_count']
                        for i_l in range(1, (l_count+1)):
                            line= obj["line"+str(i_l)]
                            if re.match("^.*\s*("+added_show+")\s+\.\.\.\sOK.*$", line) :
                                self.validDialog(added_show, "show added!")
                        self._filterSearch()
                        return
                    res= re.match("^\s*RM_SHOW\s+(\S+)\s*$", obj['invoked'])
                    if res :
                        rm_show= res.groups()[0]
                        self.validDialog(rm_show, "show removed!")
                        self._filterSearch()
                        return
                    res= re.match("^\s*COMMAND\s+(new|see|acquire|ignore)\s+(\S+)\s*$", obj['invoked'])
                    if res :
                        self._filterSearch()
                        return
                        
        if len(db)>0 :
            self._processShowDB(db)

    def change_episode_selection_tag(self, tag):
        model, paths = self.objects["ShowTreeSelection"].get_selected_rows()
        if model and paths:
            shows= ""
            for path in paths:
                if path.get_depth() > 1 :
                    iter= model.get_iter(path)
                    show= model.get_value(model.iter_parent(iter),0)
                    s= model.get_value(iter, 1)
                    e= model.get_value(iter, 2)
                    shows+= (show+'.s'+str(s).zfill(2)+'e'+str(e).zfill(2)+"* ")
            
            if shows:
                printForPipe("REQUEST TVCMD COMMAND "+tag+' '+shows)

    def check_selection(self):
        selection= self.objects["ShowTreeSelection"]
        model, paths= selection.get_selected_rows()

        toolButton= self.objects['DeleteShowToolButton']
        if model and paths and len(paths)==1 and paths[0].get_depth()==1 :
            toolButton.set_visible(True)
            toolButton.set_sensitive(True)
        else :
            toolButton.set_visible(False)
            toolButton.set_sensitive(False)

    def selected_show_delete(self):
        selection= self.objects["ShowTreeSelection"]
        model, paths= selection.get_selected_rows()

        toolButton= self.objects['DeleteShowToolButton']
        if model and paths and len(paths)==1 and paths[0].get_depth()==1 :
            iter= model.get_iter(paths[0])
            show= model.get_value(iter,0)

            if show :
                printForPipe("REQUEST TVCMD RM_SHOW "+show)





    def input_process(self, s):
        info= s.split(' ')
        _l= len(info)
        if _l<1 : return
        elif info[0] == "REQUEST":
            if _l>1:
                status= info[1]
                more= ' '.join(info[2:]) if _l>2 else None
                if (status == "EXPIRED"):
                    self.errorDialog('TIMEOUT', "Session connexion timeout")
                elif (status == "INVALID"):
                    self.errorDialog('INVALID SESSION', "Session connexion changed: is no longer valid")
                elif (status == "NO-CONNECTION"):
                    self.errorDialog('NO-CONNECTION', "Connexion failed")
                elif (status == "UNRECOGNIZED"):
                    self.errorDialog('Request: '+status, more)
                elif (status == "NO-SESSION"):
                    self.errorDialog('Request: '+status, "You don't appear to be connected…")
                elif (status == "DISCONNECTED"):
                    self.errorDialog(status, "You appear to have been disconnected")
                else :
                    self.errorDialog('Request '+status, more)
        elif info[0] == "PROCESS" or info[0] == "REQUEST_PROCESS":
            if _l>1:
                status= info[1]
                more= ' '.join(info[2:]) if _l>2 else None
                if (status == "UNKNOWN-STATUS"):
                    self.errorDialog(('Server PROCESS' if info[0] == "PROCESS" else 'Request PROCESS ') , "Invalid or unknown connexion status")
                else :
                    self.errorDialog(('Request ' if info[0] == "PROCESS" else 'Request processing ')+status, more)
        elif info[0] == "TV_CMD":
            if _l>1:
                status= info[1]
                more= ' '.join(info[2:]) if _l>2 else None
                if (status == "USELESS"):
                    self.errorDialog('Show already followed')
                elif (status == "SCRIPT_FAILURE"):
                    self.errorDialog('Server failure!','Script failure on server side!')
                elif (status == "NO-SHOW"):
                    self.errorDialog('Show doesn\'t exist…', more)
                elif (status == "NO-CMD") or (status == "INVALID-CMD"):
                    self.errorDialog('Bad command…', more)
                elif (status == "SUCCESS" and more):
                    self.processJSONAnswer(more)
                else :
                    self.errorDialog('TVCmd: '+status, more)
        elif info[0] == "QUIT":
            Gtk.main_quit()

                
                



def inputThread_function(gui):
    b= True
    while b:
        try:
            v= input()
            if(v=="QUIT") :
                b= False
            else :
                GLib.idle_add(gui.input_process, v)
                time.sleep(0.1)
        except EOFError as error:
            b= False




gui= MyGUI(HERE_PATH+"/gui.glade")
inputThread= threading.Thread(target=inputThread_function, args=(gui,), daemon=True)

inputThread.start()
gui.show()
Gtk.main()