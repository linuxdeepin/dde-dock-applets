/****************************************************************************
**
**  Copyright (C) 2011~2014 Deepin, Inc.
**                2011~2014 Wanqing Yang
**
**  Author:     Wanqing Yang <yangwanqing@linuxdeepin.com>
**  Maintainer: Wanqing Yang <yangwanqing@linuxdeepin.com>
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
import Deepin.DockAppletWidgets 1.0
import Deepin.Widgets 1.0

DockApplet{
    id: bluetoothApplet
    title: adapterAlias
    appid: adapterPath
    icon: adapterConnected ? "bluetooth-active-symbolic" : "bluetooth-disable-symbolic"

    property int xEdgePadding: 2
    property int titleSpacing: 10
    property int rootWidth: 200

    property bool adapterConnected: adapterPowered


    // helper functions
    function marshalJSON(value) {
        var valueJSON = JSON.stringify(value);
        return valueJSON
    }
    function unmarshalJSON(valueJSON) {
        if (!valueJSON) {
            print("==> [ERROR] unmarshalJSON", valueJSON)
        }
        var value = JSON.parse(valueJSON)
        return value
    }

    function showBluetooth(id){
        dbusControlCenter.ShowModule("bluetooth")
    }

    function hideBluetooth(id){
        setAppletState(false)
    }

    menu: AppletMenu{
        Component.onCompleted: {
            addItem(dsTr("_Run"), showBluetooth);
            addItem(dsTr("_Undock"), hideBluetooth);
        }
    }

    onActivate:{
        showBluetooth(0)
    }

    window: DockQuickWindow {
        id: root
        width: rootWidth
        height: content.height + xEdgePadding * 2
        color: "transparent"

        onNativeWindowDestroyed: {
            toggleAppletState("bluetooth")
            toggleAppletState("bluetooth")
        }

        onQt5ScreenDestroyed: {
            console.log("Recive onQt5ScreenDestroyed")
            mainObject.restartDockApplet()
        }

        Item {
            width: parent.width
            height: content.height
            anchors.centerIn: parent
            anchors.bottomMargin: 4

            Column {
                id: content
                width: parent.width
                spacing: 10

                DBaseLine {
                    height: 30
                    width: parent.width
                    leftMargin: 10
                    rightMargin: 10
                    color: "transparent"
                    leftLoader.sourceComponent: DssH2 {
                        elide: Text.ElideRight
                        width: 130
                        text: adapterAlias
                        color: "#ffffff"
                    }

                    rightLoader.sourceComponent: DSwitchButton {
                        Connections {
                            target: bluetoothApplet
                            onAdapterConnectedChanged: {
                                checked = adapterConnected
                            }
                        }

                        checked: adapterConnected
                        onClicked: dbus_bluetooth.SetAdapterPowered(adapterPath, checked)
                    }
                }

                Rectangle {
                    width: rootWidth
                    height: nearbyDeviceList.height
                    visible: adapterConnected
                    color: "transparent"

                    ListView{
                        id: nearbyDeviceList
                        width: parent.width
                        height: Math.min(childrenRect.height, 235)
                        clip: true

                        DScrollBar {
                            flickable: parent
                        }

                        Timer {
                            id:delayInitTimer
                            repeat: false
                            running: false
                            interval: 1000
                            onTriggered: {
                                var devInfos = unmarshalJSON(dbus_bluetooth.GetDevices(adapterPath))
                                deviceModel.clear()
                                for(var i in devInfos){
                                    deviceModel.addOrUpdateDevice(devInfos[i])
                                }
                            }
                        }

                        model: ListModel {
                            id: deviceModel
                            Component.onCompleted: {
                                delayInitTimer.start()
                            }
                            function addOrUpdateDevice(devInfo) {
                                if (isDeviceExists(devInfo)) {
                                    updateDevice(devInfo)
                                } else {
                                    addDevice(devInfo)
                                }
                            }
                            function addDevice(devInfo) {
                                var insertIndex = getInsertIndex(devInfo)
                                print("-> addBluetoothDevice", insertIndex)
                                insert(insertIndex, {
                                    "devInfo": devInfo,
                                    "adapter_path": devInfo.AdapterPath,
                                    "item_id": devInfo.Path,
                                    "item_name": devInfo.Alias,
                                    "item_state":devInfo.State
                                })
                            }
                            function updateDevice(devInfo) {
                                var i = getDeviceIndex(devInfo)
                                get(i).devInfo = devInfo
                                get(i).item_name = devInfo.Alias
                                get(i).item_state = devInfo.State
                                sortModel()
                            }
                            function removeDevice(devInfo) {
                                if (isDeviceExists(devInfo)) {
                                    var i = getDeviceIndex(devInfo)
                                    remove(i, 1)
                                }
                            }
                            function isDeviceExists(devInfo) {
                                if (getDeviceIndex(devInfo) != -1) {
                                    return true
                                }
                                return false
                            }
                            function getDeviceIndex(devInfo) {
                                for (var i=0; i<count; i++) {
                                    if (get(i).devInfo.Path == devInfo.Path) {
                                        return i
                                    }
                                }
                                return -1
                            }
                            function getInsertIndex(devInfo) {
                                for (var i=0; i<count; i++) {
                                    if (devInfo.RSSI >= get(i).devInfo.RSSI) {
                                        return i
                                    }
                                }
                                return count
                            }
                            function sortModel() {
                                var n;
                                var i;
                                for (n=0; n<count; n++) {
                                    for (i=n+1; i<count; i++) {
                                        if (get(n).devInfo.RSSI+5 < get(i).devInfo.RSSI) {
                                            move(i, n, 1);
                                            n=0; // Repeat at start since I can't swap items i and n
                                        }
                                    }
                                }
                            }

                        }

                        delegate: DeviceItem {

                            onItemClicked: {
                                if (state)
                                {
                                    dbus_bluetooth.DisconnectDevice(id)
                                    console.log("Disconnect device, id:",id)
                                }
                                else
                                {
                                    dbus_bluetooth.ConnectDevice(id)
                                    console.log("Connect device, id:",id)
                                }
                            }
                        }

                        Connections {
                            target: dbus_bluetooth
                            onDeviceAdded: {
                                var devInfo = unmarshalJSON(arg0)
                                if (devInfo.AdapterPath != adapterPath)
                                    return
                                deviceModel.addOrUpdateDevice(devInfo)
                            }
                            onDeviceRemoved: {
                                var devInfo = unmarshalJSON(arg0)
                                if (devInfo.AdapterPath != adapterPath)
                                    return
                                deviceModel.removeDevice(devInfo)
                            }
                            onDevicePropertiesChanged: {
                                var devInfo = unmarshalJSON(arg0)
                                if (devInfo.AdapterPath != adapterPath)
                                    return
                                deviceModel.addOrUpdateDevice(devInfo)
                            }
                        }
                    }
                }

            }
        }
    }

}
