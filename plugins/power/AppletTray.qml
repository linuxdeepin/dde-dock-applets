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

DockApplet {
    id: root
    title: {
        if (!dbusPower.onBattery && dbusPower.batteryState == 1){
            return dsTr("On Charging") + " %1%".arg(dbusPower.batteryPercentage)
        }
        else{
            return "%1%".arg(dbusPower.batteryPercentage)
        }
    }
    appid: "AppletPower"
    icon: getIcon()
    width: 260;
    height: 30

    property var planNames: {
        0: dsTr("Custom"),
        1: dsTr("Power saver"),
        2: dsTr("Balanced"),
        3: dsTr("High performance")
    }
    property int currentPlan: dbusPower.onBattery ? dbusPower.batteryPlan : dbusPower.linePowerPlan

    onCurrentPlanChanged: {
        menu.updateMenu()
    }

    function showPower(id){
        dbusControlCenter.ShowModule("power")
    }

    function hidePower(id){
        setAppletState(false)
    }

    onActivate: {
        showPower(0)
    }

    function do_nothing(id){
    }

    function changePowerPlan(id){
        var id_index = id.split(":")[2]
        var planIndex = menu.menuIds.indexOf(id_index)
        if(dbusPower.onBattery){
            dbusPower.batteryPlan = planIndex
        }
        else{
            dbusPower.linePowerPlan = planIndex
        }
    }

    menu: AppletMenu {
        property var menuIds: new Array()

        function updateMenu(){
            for(var i in menuIds){
                var checked = false
                if(currentPlan == i){
                    checked = true
                }
                var content_obj = unmarshalJSON(content)
                content_obj.items[menuIds[i]].checked = checked
                content = marshalJSON(content_obj)
            }
        }

        Component.onCompleted: {
            addItem(dsTr("_Run"), showPower);
            addItem("", do_nothing);
            for(var i in planNames){
                var menuId = addCheckboxItem("power_plan", planNames[i], changePowerPlan);
                menuIds.push(menuId);
            }
            addItem("", do_nothing);
            addItem(dsTr("_Undock"), hidePower);
            updateMenu()
        }
    }

    function getIcon(){
        var percentage = parseInt(dbusPower.batteryPercentage)
        if(dockDisplayMode == 0){
            if (dbusPower.onBattery){
                var iconName = "battery-%1"
            }
            else{
                var iconName = "battery-%1-plugged"
            }

            if(percentage <= 5){
                return iconName.arg("000")
            }
            else if(percentage <= 20){
                return iconName.arg("020")
            }
            else if(percentage <= 40){
                return iconName.arg("040")
            }
            else if(percentage <= 60){
                return iconName.arg("060")
            }
            else if(percentage <= 80){
                return iconName.arg("080")
            }
            else{
                return iconName.arg("100")
            }
        }
        else{
            if (!dbusPower.onBattery){
                return "battery-charged-symbolic"
            }
            else {
                var iconName = "battery-%1-symbolic"
                if(percentage <= 5){
                    return iconName.arg("000")
                }
                else if(percentage <= 20){
                    return iconName.arg("020")
                }
                else if(percentage <= 40){
                    return iconName.arg("040")
                }
                else if(percentage <= 60){
                    return iconName.arg("060")
                }
                else if(percentage <= 80){
                    return iconName.arg("080")
                }
                else{
                    return iconName.arg("100")
                }
            }
        }
    }
}
