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


class MyGUI(GObject.GObject) :
    class Handler:
        def __init__(self, parent, objects={}):
            self._parent= parent
            self._objects= objects

        def onDestroy(self, *args):
            printForPipe("QUIT")
            time.sleep(1)
            Gtk.main_quit()

        def onConnectBtnClick(self, *args):
            if ( ( ( "EntryLogin" in self._objects and self._objects["EntryLogin"] ) and 
            ( "EntryPass" in self._objects and self._objects["EntryPass"] ) ) and
            ( self._objects["EntryLogin"].get_text() and self._objects["EntryPass"].get_text() ) ) :
                if not self._parent._connected :
                    self._parent._connectedUser= self._objects["EntryLogin"].get_text()
                    printForPipe("LOGIN " + self._parent._connectedUser + " " + self._objects["EntryPass"].get_text() )
                else :
                    printForPipe("LOGOUT " + self._parent._connectedUser )
                self._objects['EntryLogin'].set_sensitive(False)
                self._objects['EntryPass'].set_sensitive(False)
                self._objects['ConnectBtn'].set_sensitive(False)

        def onFilterToggled(self, *args):
            obj= args[0]
            if obj.get_active() :
                for id in ['NewToggle', 'UpcomingToggle', 'SeenToggle', 'AcquiredToggle', 'AllToggle'] :
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
                else:
                    self._parent._onFilter= MyGUI.FILTER.ALL
                self._parent._filterSearch()

        def onShowEntered(self, *args):
            self._parent._filterSearch()

        def onShowAdd(self, *args):
            show= self._objects["ShowSearchEntry"].get_text()
            user= self._parent._connectedUser
            if show and user:
                printForPipe("REQUEST "+user+" TVCMD"+" ADD_SHOW "+show)

        def onURL(self, *args):
            printForPipe("URL_GET")

        def onRegister(self, *args):
            self._parent.registerDialog()

        def registerEntryCtrl(self, *args):
            self._objects["RegisterValidButton"].set_sensitive(
                self._objects['EntryUsername'].get_text() != '' and
                self._objects['EntryPasswordSet'].get_text() != '' and
                self._objects['EntryPasswordConfirm'].get_text() == self._objects['EntryPasswordSet'].get_text()
            )

        def onToolSetNew(self, *args):
            sys.stderr.write("TODO onToolSetNew\n")
            sys.stderr.flush()
            self._parent.change_episode_selection_tag("new")

        def onToolSetSee(self, *args):
            sys.stderr.write("TODO onToolSetSee\n")
            sys.stderr.flush()
            self._parent.change_episode_selection_tag("see")

        def onToolSetAcquire(self, *args):
            sys.stderr.write("TODO onToolSetAcquire\n")
            sys.stderr.flush()
            self._parent.change_episode_selection_tag("acquire")




    class FILTER(Enum):
        ALL=0
        NEW=1
        UPCOMING=2
        SEEN=3
        ACQUIRED=4



    def __init__(self, gladFile):
        GObject.GObject.__init__(self)
        self.builder= Gtk.Builder()
        self.builder.add_from_file(gladFile)
        self.objects= {}

        self._connected= False
        self._connectedUser= None

        self._onFilter= MyGUI.FILTER.ALL

        self._url= None
        
        for name in ['myWindow','EntryLogin','EntryPass','ConnectBtn','Stack','ShowsPage', 'WaitConnectLabel',
                    'ErrorDialog', 'ValidDialog', 'URLDialog', 'RegisterDialog',
                    'NewToggle', 'UpcomingToggle', 'SeenToggle', 'AcquiredToggle', 'AllToggle',
                    'ShowSearchEntry', 'EntryURL', 'EntryUsername', 'EntryPasswordSet', 'EntryPasswordConfirm',
                    'RegisterValidButton',
                    'ShowsTreeView', 'ShowsTreeStore', 'ShowTreeSelection'] :
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
        self._connected= True
        self._filterSearch()

    def onConnectCancel(self):
        self.objects['Stack'].set_visible_child(self.objects['WaitConnectLabel'])
        self.objects['ConnectBtn'].set_label("gtk-connect")
        self.objects['EntryLogin'].set_sensitive(True)
        self.objects['EntryPass'].set_sensitive(True)
        self.objects['ConnectBtn'].set_sensitive(True)
        self._connected= False
        self._connectedUser= None

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

    def urlDialog(self, url=None):
        dial= self.objects['URLDialog']
        urlEntry= self.objects['EntryURL']

        if url :
            urlEntry.set_text(url)

        response = dial.run()

        if response == Gtk.ResponseType.OK and len(urlEntry.get_text())>0:
            printForPipe("URL_SET "+urlEntry.get_text())            

        dial.hide()

    def registerDialog(self):
        dial= self.objects['RegisterDialog']
        userEntry= self.objects['EntryUsername']
        pass1Entry= self.objects['EntryPasswordSet']
        pass2Entry= self.objects['EntryPasswordConfirm']

        userEntry.set_text('')
        pass1Entry.set_text('')
        pass2Entry.set_text('')

        response = dial.run()

        if response == Gtk.ResponseType.OK :
            printForPipe("REGISTER "+userEntry.get_text()+' '+pass1Entry.get_text())            

        dial.hide()

    def _filterSearch(self):
        txt= self.objects["ShowSearchEntry"].get_text().lower().replace(' ','_')
        txt= (txt+'*') if txt else ''
        user= self._connectedUser
        if (user) :
            if self._onFilter == MyGUI.FILTER.ALL :
                printForPipe("REQUEST "+user+" TVCMD"+" COMMAND ls -sna "+txt)
            elif self._onFilter == MyGUI.FILTER.NEW :
                printForPipe("REQUEST "+user+" TVCMD"+" COMMAND ls -n "+txt)
            elif self._onFilter == MyGUI.FILTER.UPCOMING :
                printForPipe("REQUEST "+user+" TVCMD"+" COMMAND ls -f "+txt)
            elif self._onFilter == MyGUI.FILTER.SEEN :
                printForPipe("REQUEST "+user+" TVCMD"+" COMMAND ls -s "+txt)
            elif self._onFilter == MyGUI.FILTER.ACQUIRED:
                printForPipe("REQUEST "+user+" TVCMD"+" COMMAND ls -a "+txt)

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
                    res= re.match("^\s*ADD_SHOW\s+(\S)+\s*$", obj['invoked'])
                    if res :
                        added_show= res.groups()[0]
                        l_count= obj['line_count']
                        for i_l in range(1, (l_count+1)):
                            line= obj["line"+str(i_l)]
                            if re.match("^.*\s*("+added_show+")\s+\.\.\.\sOK.*$", line) :
                                validDialog(added_show, "show added!")
                                self._filterSearch()
                        return
                    res= re.match("^\s*RM_SHOW\s+(\S)+\s*$", obj['invoked'])
                    if res :
                        rm_show= res.groups()[0]
                        validDialog(rm_show, "show removed!")
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
            
            user= self._connectedUser
            if shows and user:
                printForPipe("REQUEST "+user+" TVCMD COMMAND "+tag+' '+shows)
                self._filterSearch()



    def input_process(self, s):
        info= s.split(' ')
        _l= len(info)
        if _l<1 : return
        elif info[0] == "SEND" :
            if _l>1 :
                status= info[1]
                if (status == "FAILURE") :
                    self.errorDialog("Connection failure", ' '.join(info[2:]))
                else :
                    self.errorDialog("Connection "+status)
        elif info[0] == "CONNECT" :
            if _l>1 :
                status= info[1]
                if (status == "CONNECTED") :
                    self.onConnect()
                else:
                    self.onConnectCancel()
                    if _l > 2 :
                        self.errorDialog(status, ' '.join(info[2:]))
                    else :
                        self.errorDialog(status)
        elif info[0] == "DISCONNECT" :
            self.onConnectCancel()
            if _l>1 and info[1] != "DISCONNECTED" :
                if _l>2 :
                    self.errorDialog(info[1], ' '.join(info[2:]))
                else :
                    self.errorDialog(info[1])
        elif info[0] == "REGISTER" :
            if _l>1 :
                status= info[1]
                if (status == "VALID") :
                    self.validDialog('REGISTERATION','Success!')
                elif (status == "UNAVAILABLE") :
                    self.errorDialog(status,"Can't use this username…")
                else:
                    more= ' '.join(info[2:]) if _l>2 else None
                    self.errorDialog('Register '+status, more)
        elif info[0] == "CHANGE_PASS" :
            if _l>1:
                status= info[1]
                if (status == "CHANGED") :
                    self.validDialog('PASSWORD CHANGE','Success!')
                    if self._connectedUser and len(self._connectedUser)>0 :
                        printForPipe("LOGOUT "+self._connectedUser)
                elif (status == "REFUSED"):
                    self.errorDialog('PASSWORD CHANGE', "Failed (bad old password match?)")
                else:
                    more= ' '.join(info[2:]) if _l>2 else None
                    self.errorDialog('Pass change '+status, more)
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
                self.onConnectCancel()
        elif info[0] == "PROCESS" or info[0] == "REQUEST_PROCESS":
            if _l>1:
                status= info[1]
                more= ' '.join(info[2:]) if _l>2 else None
                if (status == "UNKNOWN-STATUS"):
                    self.errorDialog(('Server PROCESS' if info[0] == "PROCESS" else 'Request PROCESS ') , "Invalid or unknown connexion status")
                else :
                    self.errorDialog(('Request ' if info[0] == "PROCESS" else 'Request processing ')+status, more)
        elif info[0] == "GET_URL":
            if _l>1:
                status= info[1]
                more= ' '.join(info[2:]) if _l>2 else None
                if (status == "FOUND"):
                    self.urlDialog(more)
                else:
                    self.errorDialog('Get URL '+status, more)
        elif info[0] == "SET_URL":
            if _l>2:
                status= info[1]
                more= ' '.join(info[2:])
                if (status == "SET"):
                    self._url= more
                else:
                    self.errorDialog('Set URL '+status, more)
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