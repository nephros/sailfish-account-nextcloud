/****************************************************************************************
**
** Copyright (C) 2019 Open Mobile Platform LLC
** All rights reserved.
**
** License: Proprietary.
**
****************************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.gallery 1.0
import com.jolla.gallery.nextcloud 1.0
import org.nemomobile.models 1.0

MediaSourcePage {
    id: root

    SearchModel {
        id: searchModel
        sourceModel: root.model
        searchRoles: [ "albumName" ]
        matchType: SearchModel.MatchAnywhere
        caseSensitivity: Qt.CaseInsensitive
    }

    SilicaListView {
        id: view
        anchors.fill: parent
        header: MediaSearchHeader {
            width: view.width
            title: root.model.userDisplayName || root.model.userId
            model: root.searchModel
        }
        cacheBuffer: Screen.height
        model: root.searchModel

        delegate: NextcloudAlbumDelegate {
            accountId: model.accountId
            userId: model.userId
            albumId: model.albumId
            albumName: model.albumName.length > 0
                       ? model.albumName
                       : "Photos" // not translated, this is the non-localized root Nextcloud photos directory
            albumThumbnailPath: model.thumbnailPath
            photoCount: model.photoCount
            usePlaceholderColor: model.albumName.length === 0

            onClicked: {
                var props = {
                    "accountId": accountId,
                    "userId": userId,
                    "albumId": albumId,
                    "albumName": albumName
                }
                pageStack.animatorPush(Qt.resolvedUrl("NextcloudPhotoListPage.qml"), props)
            }
        }

        VerticalScrollDecorator {}
    }
}
