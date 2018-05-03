import UM 1.2 as UM
import Cura 1.0 as Cura

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1
import QtQuick.Window 2.1

Cura.MachineAction
{
    id: base
    anchors.fill: parent;
    property var selectedInstance: null
    Column
    {
        anchors.fill: parent;
        id: discoverOctoPrintAction

        spacing: UM.Theme.getSize("default_margin").height

        SystemPalette { id: palette }
        UM.I18nCatalog { id: catalog; name:"cura" }
        Label
        {
            id: pageTitle
            width: parent.width
            text: catalog.i18nc("@title", "Connect to OctoPrint")
            wrapMode: Text.WordWrap
            font.pointSize: 18
        }

        Label
        {
            id: pageDescription
            width: parent.width
            wrapMode: Text.WordWrap
            text: catalog.i18nc("@label", "Select your OctoPrint instance from the list below:")
        }

        Row
        {
            spacing: UM.Theme.getSize("default_lining").width

            Button
            {
                id: addButton
                text: catalog.i18nc("@action:button", "Add");
                onClicked:
                {
                    manualPrinterDialog.showDialog("", "", "80", "/", false, "", "");
                }
            }

            Button
            {
                id: editButton
                text: catalog.i18nc("@action:button", "Edit")
                enabled: base.selectedInstance != null && base.selectedInstance.getProperty("manual") == "true"
                onClicked:
                {
                    manualPrinterDialog.showDialog(base.selectedInstance.name, base.selectedInstance.ipAddress,
                                                   base.selectedInstance.port, base.selectedInstance.path,
                                                   base.selectedInstance.getProperty("useHttps") == "true",
                                                   base.selectedInstance.getProperty("userName"), base.selectedInstance.getProperty("password"));
                }
            }

            Button
            {
                id: removeButton
                text: catalog.i18nc("@action:button", "Remove")
                enabled: base.selectedInstance != null && base.selectedInstance.getProperty("manual") == "true"
                onClicked: manager.removeManualInstance(base.selectedInstance.name)
            }

            Button
            {
                id: rediscoverButton
                text: catalog.i18nc("@action:button", "Refresh")
                onClicked: manager.startDiscovery()
            }
        }

        Row
        {
            width: parent.width
            spacing: UM.Theme.getSize("default_margin").width
            ScrollView
            {
                id: objectListContainer
                frameVisible: true
                width: (parent.width * 0.5) | 0
                height: base.height - parent.y

                Rectangle
                {
                    parent: viewport
                    anchors.fill: parent
                    color: palette.light
                }

                ListView
                {
                    id: listview
                    model: manager.discoveredInstances
                    onModelChanged:
                    {
                        var selectedKey = manager.getStoredKey();
                        for(var i = 0; i < model.length; i++) {
                            if(model[i].getKey() == selectedKey)
                            {
                                currentIndex = i;
                                return
                            }
                        }
                        currentIndex = -1;
                    }
                    width: parent.width
                    currentIndex: activeIndex
                    onCurrentIndexChanged:
                    {
                        base.selectedInstance = listview.model[currentIndex];
                        apiCheckDelay.throttledCheck();
                    }
                    Component.onCompleted: manager.startDiscovery()
                    delegate: Rectangle
                    {
                        height: childrenRect.height
                        color: ListView.isCurrentItem ? palette.highlight : index % 2 ? palette.base : palette.alternateBase
                        width: parent.width
                        Label
                        {
                            anchors.left: parent.left
                            anchors.leftMargin: UM.Theme.getSize("default_margin").width
                            anchors.right: parent.right
                            text: listview.model[index].name
                            color: parent.ListView.isCurrentItem ? palette.highlightedText : palette.text
                            elide: Text.ElideRight
                        }

                        MouseArea
                        {
                            anchors.fill: parent;
                            onClicked:
                            {
                                if(!parent.ListView.isCurrentItem)
                                {
                                    parent.ListView.view.currentIndex = index;
                                }
                            }
                        }
                    }
                }
            }
            Column
            {
                width: (parent.width * 0.5) | 0
                spacing: UM.Theme.getSize("default_margin").height
                Label
                {
                    visible: base.selectedInstance != null
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: base.selectedInstance ? base.selectedInstance.name : ""
                    font.pointSize: 16
                    elide: Text.ElideRight
                }
                Grid
                {
                    visible: base.selectedInstance != null
                    width: parent.width
                    columns: 2
                    rowSpacing: UM.Theme.getSize("default_lining").height
                    Label
                    {
                        width: (parent.width * 0.2) | 0
                        wrapMode: Text.WordWrap
                        text: catalog.i18nc("@label", "Version")
                    }
                    Label
                    {
                        width: (parent.width * 0.75) | 0
                        wrapMode: Text.WordWrap
                        text: base.selectedInstance ? base.selectedInstance.octoprintVersion : ""
                    }
                    Label
                    {
                        width: (parent.width * 0.2) | 0
                        wrapMode: Text.WordWrap
                        text: catalog.i18nc("@label", "Address")
                    }
                    Label
                    {
                        width: (parent.width * 0.7) | 0
                        wrapMode: Text.WordWrap
                        text: base.selectedInstance ? "%1:%2".arg(base.selectedInstance.ipAddress).arg(String(base.selectedInstance.port)) : ""
                    }
                    Label
                    {
                        width: (parent.width * 0.2) | 0
                        wrapMode: Text.WordWrap
                        text: catalog.i18nc("@label", "API Key")
                    }
                    TextField
                    {
                        id: apiKey
                        width: (parent.width * 0.8 - UM.Theme.getSize("default_margin").width) | 0
                        text: manager.apiKey
                        onTextChanged:
                        {
                            apiCheckDelay.throttledCheck()
                        }
                    }
                    Timer
                    {
                        id: apiCheckDelay
                        interval: 500

                        signal throttledCheck
                        signal check
                        property bool checkOnTrigger: false

                        onThrottledCheck:
                        {
                            if(running)
                            {
                                checkOnTrigger = true;
                            }
                            else
                            {
                                check();
                            }
                        }
                        onCheck:
                        {
                            manager.testApiKey(base.selectedInstance.baseURL, apiKey.text, base.selectedInstance.getProperty("userName"), base.selectedInstance.getProperty("password"))
                            checkOnTrigger = false;
                            restart();
                        }
                        onTriggered:
                        {
                            if(checkOnTrigger)
                            {
                                check();
                            }
                        }
                    }
                }

                Label
                {
                    visible: base.selectedInstance != null && text != ""
                    text:
                    {
                        var result = ""
                        if (apiKey.text == "")
                        {
                            result = catalog.i18nc("@label", "Please enter the API key to access OctoPrint.");
                        }
                        else
                        {
                            if(manager.instanceResponded)
                            {
                                if(manager.instanceApiKeyAccepted)
                                {
                                    return "";
                                }
                                else
                                {
                                    result = catalog.i18nc("@label", "The API key is not valid.");
                                }
                            }
                            else
                            {
                                return catalog.i18nc("@label", "Checking the API key...")
                            }
                        }
                        result += " " + catalog.i18nc("@label", "You can get the API key through the OctoPrint web page.");
                        return result;
                    }
                    width: parent.width - UM.Theme.getSize("default_margin").width
                    wrapMode: Text.WordWrap
                }

                Column
                {
                    visible: base.selectedInstance != null
                    width: parent.width
                    spacing: UM.Theme.getSize("default_lining").height

                    CheckBox
                    {
                        id: autoPrintCheckBox
                        text: catalog.i18nc("@label", "Automatically start print job after uploading")
                        enabled: manager.instanceApiKeyAccepted
                        checked: manager.instanceApiKeyAccepted && Cura.ContainerManager.getContainerMetaDataEntry(Cura.MachineManager.activeMachineId, "octoprint_auto_print") != "false"
                        onClicked:
                        {
                            manager.setContainerMetaDataEntry(Cura.MachineManager.activeMachineId, "octoprint_auto_print", String(checked))
                        }
                    }
                    CheckBox
                    {
                        id: showCameraCheckBox
                        text: catalog.i18nc("@label", "Show webcam image")
                        enabled: manager.instanceSupportsCamera
                        checked: manager.instanceApiKeyAccepted && Cura.ContainerManager.getContainerMetaDataEntry(Cura.MachineManager.activeMachineId, "octoprint_show_camera") == "true"
                        onClicked:
                        {
                            manager.setContainerMetaDataEntry(Cura.MachineManager.activeMachineId, "octoprint_show_camera", String(checked))
                        }
                    }
                    CheckBox
                    {
                        id: storeOnSdCheckBox
                        text: catalog.i18nc("@label", "Store G-code on the printer SD card")
                        enabled: manager.instanceSupportsSd
                        checked: manager.instanceApiKeyAccepted && Cura.ContainerManager.getContainerMetaDataEntry(Cura.MachineManager.activeMachineId, "octoprint_store_sd") == "true"
                        onClicked:
                        {
                            manager.setContainerMetaDataEntry(Cura.MachineManager.activeMachineId, "octoprint_store_sd", String(checked))
                        }
                    }
                    Label
                    {
                        visible: storeOnSdCheckBox.checked
                        wrapMode: Text.WordWrap
                        width: parent.width
                        text: catalog.i18nc("@label", "Note: Transfering files to the printer SD card takes very long. Using this option is not recommended.")
                    }
                    CheckBox
                    {
                        id: fixGcodeFlavor
                        text: catalog.i18nc("@label", "Set Gcode flavor to \"Marlin\"")
                        checked: true
                        visible: machineGCodeFlavorProvider.properties.value == "UltiGCode"
                    }
                    Label
                    {
                        text: catalog.i18nc("@label", "Note: Printing UltiGCode using OctoPrint does not work. Setting Gcode flavor to \"Marlin\" fixes this, but overrides material settings on your printer.")
                        width: parent.width - UM.Theme.getSize("default_margin").width
                        wrapMode: Text.WordWrap
                        visible: fixGcodeFlavor.visible
                    }
                }

                Flow
                {
                    visible: base.selectedInstance != null
                    spacing: UM.Theme.getSize("default_margin").width

                    Button
                    {
                        text: catalog.i18nc("@action", "Open in browser...")
                        onClicked: manager.openWebPage(base.selectedInstance.baseURL)
                    }

                    Button
                    {
                        text: catalog.i18nc("@action:button", "Connect")
                        enabled: apiKey.text != "" && manager.instanceApiKeyAccepted
                        onClicked:
                        {
                            if(fixGcodeFlavor.visible)
                            {
                                manager.applyGcodeFlavorFix(fixGcodeFlavor.checked)
                            }
                            manager.setKey(base.selectedInstance.getKey())
                            manager.setApiKey(apiKey.text)
                            completed()
                        }
                    }
                }
            }
        }
    }

    UM.SettingPropertyProvider
    {
        id: machineGCodeFlavorProvider

        containerStackId: Cura.MachineManager.activeMachineId
        key: "machine_gcode_flavor"
        watchedProperties: [ "value" ]
        storeIndex: 4
    }

    UM.Dialog
    {
        id: manualPrinterDialog
        property string oldName
        property alias nameText: nameField.text
        property alias addressText: addressField.text
        property alias portText: portField.text
        property alias pathText: pathField.text
        property alias userNameText: userNameField.text
        property alias passwordText: passwordField.text

        title: catalog.i18nc("@title:window", "Manually added OctoPrint instance")

        minimumWidth: 400 * screenScaleFactor
        minimumHeight: (showAdvancedOptions.checked ? 280 : 160) * screenScaleFactor
        width: minimumWidth
        height: minimumHeight

        signal showDialog(string name, string address, string port, string path_, bool useHttps, string userName, string password)
        onShowDialog:
        {
            oldName = name;
            nameText = name;
            nameField.selectAll();
            nameField.focus = true;

            addressText = address;
            portText = port;
            pathText = path_;
            httpsCheckbox.checked = useHttps;
            userNameText = userName;
            passwordText = password;

            manualPrinterDialog.show();
        }

        onAccepted:
        {
            if(oldName != nameText)
            {
                manager.removeManualInstance(oldName);
            }
            if(portText == "")
            {
                portText = "80" // default http port
            }
            if(pathText.substr(0,1) != "/")
            {
                pathText = "/" + pathText // ensure absolute path
            }
            manager.setManualInstance(nameText, addressText, parseInt(portText), pathText, httpsCheckbox.checked, userNameText, passwordText)
        }

        Column {
            anchors.fill: parent
            spacing: UM.Theme.getSize("default_margin").height

            Grid
            {
                columns: 2
                width: parent.width
                verticalItemAlignment: Grid.AlignVCenter
                rowSpacing: UM.Theme.getSize("default_lining").height

                Label
                {
                    text: catalog.i18nc("@label","Instance Name")
                    width: (parent.width * 0.4) | 0
                }

                TextField
                {
                    id: nameField
                    maximumLength: 20
                    width: (parent.width * 0.6) | 0
                    validator: RegExpValidator
                    {
                        regExp: /[a-zA-Z0-9\.\-\_]*/
                    }
                }

                Label
                {
                    text: catalog.i18nc("@label","IP Address or Hostname")
                    width: (parent.width * 0.4) | 0
                }

                TextField
                {
                    id: addressField
                    maximumLength: 30
                    width: (parent.width * 0.6) | 0
                    validator: RegExpValidator
                    {
                        regExp: /[a-zA-Z0-9\.\-\_]*/
                    }
                }

                Label
                {
                    text: catalog.i18nc("@label","Port Number")
                    width: (parent.width * 0.4) | 0
                }

                TextField
                {
                    id: portField
                    maximumLength: 5
                    width: (parent.width * 0.6) | 0
                    validator: RegExpValidator
                    {
                        regExp: /[0-9]*/
                    }
                }

                Label
                {
                    text: catalog.i18nc("@label","Path")
                    width: (parent.width * 0.4) | 0
                }

                TextField
                {
                    id: pathField
                    maximumLength: 30
                    width: (parent.width * 0.6) | 0
                    validator: RegExpValidator
                    {
                        regExp: /[a-zA-Z0-9\.\-\_\/]*/
                    }
                }
            }

            CheckBox
            {
                id: showAdvancedOptions
                text: catalog.i18nc("@label","Show reverse proxy options (advanced)")
            }

            Grid
            {
                columns: 2
                visible: showAdvancedOptions.checked
                width: parent.width
                verticalItemAlignment: Grid.AlignVCenter
                rowSpacing: UM.Theme.getSize("default_lining").height

                Label
                {
                    text: catalog.i18nc("@label","Use HTTPS")
                    width: (parent.width * 0.4) | 0
                }

                CheckBox
                {
                    id: httpsCheckbox
                }

                Label
                {
                    text: catalog.i18nc("@label","HTTP user name")
                    width: (parent.width * 0.4) | 0
                }

                TextField
                {
                    id: userNameField
                    maximumLength: 64
                    width: (parent.width * 0.6) | 0
                }

                Label
                {
                    text: catalog.i18nc("@label","HTTP password")
                    width: (parent.width * 0.4) | 0
                }

                TextField
                {
                    id: passwordField
                    maximumLength: 64
                    width: (parent.width * 0.6) | 0
                    echoMode: TextInput.PasswordEchoOnEdit
                }


            }

            Label
            {
                visible: showAdvancedOptions.checked
                wrapMode: Text.WordWrap
                width: parent.width
                text: catalog.i18nc("@label","NB: Only use these options if you access OctoPrint through a reverse proxy.")
            }
        }

        rightButtons: [
            Button {
                text: catalog.i18nc("@action:button","Cancel")
                onClicked:
                {
                    manualPrinterDialog.reject()
                    manualPrinterDialog.hide()
                }
            },
            Button {
                text: catalog.i18nc("@action:button", "Ok")
                onClicked:
                {
                    manualPrinterDialog.accept()
                    manualPrinterDialog.hide()
                }
                enabled: manualPrinterDialog.nameText.trim() != "" && manualPrinterDialog.addressText.trim() != ""
                isDefault: true
            }
        ]
    }
}