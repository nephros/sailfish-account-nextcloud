// SPDX-FileCopyrightText: 2019 - 2020 Open Mobile Platform LLC
// SPDX-FileCopyrightText: 2020 - 2023 Jolla Ltd.
// SPDX-FileCopyrightText: 2024 - 2025 Jolla Mobile Ltd
//
// SPDX-License-Identifier: BSD-3-Clause

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Gallery 1.0
import Sailfish.FileManager 1.0
import com.jolla.gallery 1.0
import com.jolla.gallery.nextcloud 1.0

Page {
    id: root

    property alias accountId: photoModel.accountId
    property alias userId: photoModel.userId
    property alias albumId: photoModel.albumId
    property string albumName

    NextcloudPhotoModel {
        id: photoModel

        imageCache: NextcloudImageCache
    }

    SilicaGridView {
        id: grid
        anchors.fill: parent
        model: photoModel
        cellWidth: isLandscape ? parent.width/6 : parent.width/4
        cellHeight: cellWidth

        header: PageHeader {
            title: {
                if (albumName.length > 0) {
                    var lastSlash = albumName.lastIndexOf('/')
                    return lastSlash >= 0 ? albumName.substring(lastSlash + 1) : albumName
                }
                //: Heading for Nextcloud photos
                //% "Nextcloud"
                return qsTrId("jolla_gallery_nextcloud-la-nextcloud")
            }
        }

        delegate: GridItem {
            id: photoDelegate

            width: grid.cellWidth
            height: grid.cellHeight

            Image {
                id: image

                anchors.centerIn: parent
                width: parent.width
                height: parent.height

                sourceSize.width: width
                sourceSize.height: width

                fillMode: thumbDownloader.status === NextcloudImageDownloader.Ready
                    ? Image.preserveAspectCrop
                    : Image.Pad
                clip: thumbDownloader.status === NextcloudImageDownloader.Ready
                source: thumbDownloader.status === NextcloudImageDownloader.Ready
                        ? thumbDownloader.imagePath
                        : Theme.iconForMimeType(model.fileType)
                         + ( thumbDownloader.status === NextcloudImageDownloader.Error ? "?" + Theme.errorColor : "")
                opacity: thumbDownloader.status === NextcloudImageDownloader.Ready
                         ? 1 : Theme.opacityLow
                Behavior on opacity { FadeAnimator {} }
            }

            BusyIndicator {
                running: visible && (thumbDownloader.status === NextcloudImageDownloader.Downloading)
                anchors.centerIn: parent
            }

            Label {
                anchors.centerIn: parent
                width: parent.width - Theme.paddingLarge
                visible: thumbDownloader.status === NextcloudImageDownloader.Error
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                color: Theme.secondaryColor
                //: Error label for Nextcloud photos
                //% "Loading failed"
                text: qsTrId("jolla_gallery_nextcloud-la-loading-failed")
            }

            onClicked: {
                var props = {
                    "imageModel": photoModel,
                    "currentIndex": model.index
                }
                pageStack.push(Qt.resolvedUrl("NextcloudFullscreenPhotoPage.qml"), props)
            }

            NextcloudImageDownloader {
                id: thumbDownloader

                imageCache: NextcloudImageCache
                downloadThumbnail: true
                accountId: model.accountId
                userId: model.userId
                albumId: model.albumId
                photoId: model.photoId
            }
        }
    }
}
