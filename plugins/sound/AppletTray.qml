/****************************************************************************
**
**  Copyright (C) 2011~2014 Deepin, Inc.
**                2011~2014 Kaisheng Ye
**
**  Author:     Kaisheng Ye <kaisheng.ye@gmail.com>
**  Maintainer: Kaisheng Ye <kaisheng.ye@gmail.com>
**
**  This program is free software: you can redistribute it and/or modify
**  it under the terms of the GNU General Public License as published by
**  the Free Software Foundation, either version 3 of the License, or
**  any later version.
**
**  This program is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**  GNU General Public License for more details.
**
**  You should have received a copy of the GNU General Public License
**  along with this program.  If not, see <http://www.gnu.org/licenses/>.
**
****************************************************************************/

import QtQuick 2.0
import QtQuick.Window 2.1
import Deepin.DockAppletWidgets 1.0
import Deepin.Widgets 1.0
import DBus.Com.Deepin.Daemon.Audio 1.0

DockApplet{
    id: soundApplet
    title: "Sound"
    appid: "AppletSound"
    icon: getIcon()

    property int xEdgePadding: 18
    property int titleSpacing: 10
    property int rootWidth: 224
    property int wheelStep: 5

    property var dbusAudio: Audio {}
    property var defaultSink: {
        var sinks = dbusAudio.sinks
        for(var i=0; i<sinks.length; i++){
            var obj = sinkComponent.createObject(soundApplet, { path: sinks[i] })
            if(obj.name == dbusAudio.defaultSink){
                return obj
            }
        }
    }
    property var sinkInputs: dbusAudio.sinkInputs

    onSinkInputsChanged: {
        appVolumeControlList.updateModel()
    }

    Component {
        id: sinkComponent
        AudioSink {}
    }

    Component {
        id: sinkInputComponent
        AudioSinkInput {}
    }

    function getVolume(){
        return parseInt(defaultSink.volume * 100)
    }

    function setVolume(vol, sound){
        defaultSink.SetVolume(vol/100, sound)
    }

    function getIcon(){
        if(typeof(defaultSink.volume) == "undefined"){
            if (dockDisplayMode == 0){
                return "audio-volume-000-muted"
            }
            else{
                return "audio-volume-muted-symbolic"
            }
        }

        if (dockDisplayMode == 0){
            if(defaultSink.mute){
                var iconName = "audio-volume-%1-muted"
            }
            else{
                var iconName = "audio-volume-%1"
            }
            var vol = getVolume()
            if(vol < 10){
                return iconName.arg("000")
            }
            else if (vol <= 90){
                var tmp = parseInt(vol/10) * 10
                return iconName.arg("0" + String(tmp))
            }
            else{
                return iconName.arg("100")
            }
        }
        else{
            return getSymbolicIcon()
        }
    }

    function getSymbolicIcon(){
        if(defaultSink.mute){
            return "audio-volume-muted-symbolic"
        }
        else{
            var vol = getVolume()
            if(typeof(vol) == "undefined"){
                return "audio-volume-high-symbolic"
            }

            if(vol==0){
                return "audio-volume-muted-symbolic"
            }
            else if(vol < 33){
                return "audio-volume-low-symbolic"
            }
            else if(vol < 66){
                return "audio-volume-medium-symbolic"
            }
            else{
                return "audio-volume-high-symbolic"
            }
        }
    }

    onActivate:{
        showSound(0)
    }

    Timer{
        id: onMousewheelTimer
        property bool isOnWheel: false
        interval: 300
        onTriggered: {
            if(isOnWheel){
                isOnWheel = true
            }
        }
    }

    onMousewheel: {
        onMousewheelTimer.isOnWheel = true
        var currentVolume = getVolume()
        if (angleDelta > 0){
            if(currentVolume <= (100 - wheelStep)){
                setVolume(currentVolume + wheelStep, true)
            }
            else{
                setVolume(100, true)
            }
        }
        else if(angleDelta < 0){
            if(currentVolume >= wheelStep){
                setVolume(currentVolume - wheelStep, true)
            }
            else{
                setVolume(0, true)
            }
        }
        onMousewheelTimer.restart()
    }

    function showSound(id){
        dbusControlCenter.ShowModule("sound")
    }

    function hideSound(id){
        setAppletState(false)
    }

    menu: AppletMenu{
        Component.onCompleted: {
            addItem(dsTr("_Run"), showSound);
            addItem(dsTr("_Undock"), hideSound);
        }
    }

    window: DockQuickWindow {
        id: root
        width: rootWidth
        height: content.height + xEdgePadding * 2
        color: "transparent"

        onNativeWindowDestroyed: {
            mainObject.restartDockApplet()
        }
        onQt5ScreenDestroyed: {
            console.log("Recive onQt5ScreenDestroyed")
            mainObject.restartDockApplet()
        }

        Connections{
            target: defaultSink
            onVolumeChanged: {
                if(!soundSlider.pressed && !soundSlider.hovered){
                    soundSlider.value = getVolume()
                }
            }
        }

        Item {
            width: parent.width - xEdgePadding*2
            height: content.height
            anchors.centerIn: parent

            Column {
                id: content
                width: parent.width

                Item {
                    height: 30
                    width: parent.width

                    DssH2 {
                        id: allSoundLabel
                        anchors.verticalCenter: parent.verticalCenter
                        text: dsTr("Device")
                    }

                    Rectangle {
                        height: 1
                        width: parent.width - allSoundLabel.width - titleSpacing
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: 0.1
                    }
                }

                Item {
                    height: 40
                    width: parent.width

                    DIcon {
                        id: soundImage
                        width: 24
                        height: 24
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        theme: "Deepin"
                        icon: getSymbolicIcon()

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                defaultSink.SetMute(!defaultSink.mute)
                            }
                        }
                    }

                    AppletWhiteSlider{
                        id: soundSlider
                        width: parent.width - soundImage.width - soundImage.anchors.leftMargin - titleSpacing
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        minimumValue: 0
                        maximumValue: 100
                        stepSize: 1

                        onValueChanged: {
                            if(pressed || hovered){
                                setVolume(value, false)
                            }
                        }

                        onPressedChanged: {
                            if(!pressed){
                                setVolume(value, true)
                            }
                        }

                        Timer{
                            running: true
                            interval: 200
                            onTriggered: {
                                soundSlider.value = getVolume()
                            }
                        }
                    }
                }

                Item {
                    height: 10
                    width: parent.width
                    visible: sinkInputs.length > 0
                }

                Item {
                    id: appSoundTitleBox
                    height: 30
                    width: parent.width
                    visible: sinkInputs.length > 0

                    DssH2 {
                        id: appLabel
                        text: dsTr("Applications")
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        height: 1
                        width: parent.width - appLabel.width - titleSpacing
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: 0.1
                    }
                }

                Item {
                    width: parent.width
                    height: childrenRect.height
                    visible: sinkInputs.length > 0

                    ListView {
                        id: appVolumeControlList
                        width: parent.width
                        height: childrenRect.height

                        function updateModel(){
                            if(sinkInputs.length>0){
                                model.clear()
                                for(var i=0; i<sinkInputs.length; i++){
                                    model.append({
                                        "sinkInputPath": sinkInputs[i]
                                    })
                                }
                            }
                        }

                        model: ListModel {}
                        delegate: Item {
                            id: appVolumeControlItem
                            height: 32
                            width: ListView.view.width

                            property var sinkInputObject: sinkInputComponent.createObject(appVolumeControlItem, { path: sinkInputPath })

                            Item {
                                height: 24
                                width: parent.width
                                anchors.verticalCenter: parent.verticalCenter

                                Item {
                                    id: appIconBox
                                    width: 40
                                    height: parent.height

                                    Item {
                                        height: parent.height
                                        width: parent.height
                                        anchors.left: parent.left
                                        anchors.leftMargin: 10

                                        DIcon {
                                            anchors.fill: parent
                                            theme: "Deepin"
                                            icon: sinkInputObject.icon
                                        }

                                        Image {
                                            anchors.fill: parent
                                            source: "images/app-mute.png"
                                            visible: sinkInputObject.mute
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                sinkInputObject.SetMute(!sinkInputObject.mute)
                                            }
                                        }
                                    }
                                }

                                AppletWhiteSlider{
                                    id: appSlider
                                    width: parent.width - appIconBox.width - anchors.leftMargin
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: appIconBox.right
                                    anchors.leftMargin: 10
                                    minimumValue: 0
                                    maximumValue: 1.0
                                    stepSize: 0.01

                                    onValueChanged: {
                                        if(pressed || hovered){
                                            sinkInputObject.SetVolume(value, false)
                                        }
                                    }

                                    Connections{
                                        target: sinkInputObject
                                        onVolumeChanged: {
                                            appSlider.value = sinkInputObject.volume
                                        }
                                    }

                                    Timer{
                                        running: true
                                        interval: 200
                                        onTriggered: {
                                            if(sinkInputObject.volume){
                                                appSlider.value = sinkInputObject.volume
                                                print("New SinkInput init:", sinkInputObject.name)
                                            }
                                        }
                                    }

                                }

                            }
                        }

                        Component.onCompleted: updateModel()

                    }
                }
            }
        }
    }
}
