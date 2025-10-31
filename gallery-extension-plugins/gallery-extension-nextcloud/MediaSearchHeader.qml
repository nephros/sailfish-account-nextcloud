// SPDX-FileCopyrightText: 2025 Jolla Mobile Ltd
//
// SPDX-License-Identifier: BSD-3-Clause
import QtQuick 2.6
import Sailfish.Silica 1.0

FocusScope {
    id: container
    property string title
    property var model
    readonly property bool active: searchField.text.length > 0

    visible: active || (!!model && (model.count > 0))
    implicitHeight: col.height

    Column {
        id: col
        width: parent.width
        PageHeader {
            //: Nextcloud Albums header text
            //% "Albums"
            title: qsTrId("jolla_gallery_nextcloud-la-user_albums")
            description: container.title
        }
        SearchField {
            id: searchField
            width: parent.width
            //: Nextcloud Albums search field placeholder text
            //% "Search albums"
            placeholderText: qsTrId("jolla_gallery_nextcloud-ph-search_albums")
            EnterKey.iconSource: "image://theme/icon-m-enter-accept"
            onTextChanged: if((text.length == 0) || (text.length > 3)) searchModel.pattern = text
        }
    }
}
