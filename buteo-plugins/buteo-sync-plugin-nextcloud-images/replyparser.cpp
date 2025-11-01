/****************************************************************************************
**
** Copyright (c) 2019 Open Mobile Platform LLC.
** All rights reserved.
**
** License: Proprietary.
**
****************************************************************************************/

#include "replyparser_p.h"
#include "syncer_p.h"
#include "logging.h"

#include <QtCore/QUrl>
#include <QtCore/QUrlQuery>


namespace {

QString parentAlbumId(const QString &albumId)
{
    const int baseNameSep = albumId.lastIndexOf('/', -2); // ignore any trailing slash
    if (baseNameSep < 0) {
        return QString();
    }
    return albumId.mid(0, baseNameSep + 1);
}

QString appendDirSeparator(const QString &path)
{
    return path.endsWith('/') ? path : path + '/';
}

QString removeEdgeDirSeparators(const QString &path)
{
    return path.endsWith('/') ? path.mid(0, path.length() - 1) : path;
}

}

ReplyParser::GalleryMetadata ReplyParser::galleryMetadataFromResources(Syncer *imageSyncer,
                                                                       const QString &rootPath,
                                                                       const QString &queriedAlbumPath,
                                                                       const QList<NetworkReplyParser::Resource> &resources)
{
    ReplyParser::GalleryMetadata metadata;
    int queriedAlbumPhotoCount = 0;
    const QString normalizedRootPath = appendDirSeparator(rootPath);
    const QString normalizedQueriedAlbumPath = appendDirSeparator(queriedAlbumPath);

    for (const NetworkReplyParser::Resource &resource : resources) {
        if (!resource.isCollection
                && !resource.contentType.startsWith(QStringLiteral("image/"), Qt::CaseInsensitive)) {
            continue; // TODO: support video also.
        }

        QString albumId;
        if (resource.isCollection) {
            albumId = appendDirSeparator(resource.href);
        } else {
            albumId = resource.href.mid(0, resource.href.lastIndexOf('/') + 1);
        }
        // relative path; empty if albumId is root directory
        const QString albumName = removeEdgeDirSeparators(albumId.mid(normalizedRootPath.length()));
        const bool isQueriedAlbum = (resource.isCollection && normalizedQueriedAlbumPath == albumId);

        // Examples:
        // normalizedRootPath = /remote.php/dav/files/Me/Photos/
        // normalizedQueriedAlbumPath = /remote.php/dav/files/Me/Photos/mydir/ (if mydir is the queried album)
        // albumId = /remote.php/dav/files/Me/Photos/mydir/
        // albumName = Photos/mydir
        // resource.href = [file] /remote.php/dav/files/Me/Photos/mydir/20191011_143815.jpg
        //        [or collection] /remote.php/dav/files/Me/Photos/mydir/

        if (resource.isCollection) {
            SyncCache::Album newAlbum;
            SyncCache::Album *album = isQueriedAlbum ? &metadata.album : &newAlbum;

            album->accountId = imageSyncer->accountId();
            album->userId = resource.ownerId;
            album->albumId = albumId;
            album->albumName = albumName;
            if (isQueriedAlbum) {
                album->parentAlbumId = normalizedQueriedAlbumPath == normalizedRootPath
                        ? QString()
                        : parentAlbumId(albumId);
            } else {
                album->parentAlbumId = normalizedQueriedAlbumPath;
            }
            album->photoCount = 0;
            album->etag = resource.etag;

            if (!isQueriedAlbum) {
                metadata.subAlbums.append(newAlbum);
            }
        } else {
            SyncCache::Photo photo;
            photo.accountId = imageSyncer->accountId();
            photo.userId = resource.ownerId;
            photo.albumId = albumId;
            photo.photoId = resource.fileId;
            photo.updatedTimestamp = resource.lastModified;
            photo.createdTimestamp = photo.updatedTimestamp;
            photo.fileName = resource.href.mid(resource.href.lastIndexOf('/') + 1);
            photo.albumPath = albumName;
            photo.imageUrl = imageSyncer->serverUrl();
            photo.imageUrl.setPath(resource.href);
            photo.fileSize = resource.size;
            photo.fileType = resource.contentType;
            photo.etag = resource.etag;

            QUrl tnUrl(imageSyncer->serverUrl());
            tnUrl.setPath(QStringLiteral("/index.php/core/preview")); // FIXME: root path may not be server/core but /server/somelocation/core!
            qCDebug(lcNextcloud) << "Server Core path: and core:" << tnUrl.toString();
            QUrlQuery tnQuery;
            tnQuery.addQueryItem(QStringLiteral("fileId"), resource.fileId);
            tnQuery.addQueryItem(QStringLiteral("forceIcon"), QString::number(0));
            tnQuery.addQueryItem(QStringLiteral("a"), QString::number(0));
            tnQuery.addQueryItem(QStringLiteral("x"), QString::number(320));
            tnQuery.addQueryItem(QStringLiteral("y"), QString::number(320));
            tnUrl.setQuery(tnQuery);
            qCDebug(lcNextcloud) << "Setting TN URL for" << resource.fileId << "in" << albumId << "to:" << tnUrl.toString();

            photo.thumbnailUrl = tnUrl;

            metadata.photos.append(photo);
            queriedAlbumPhotoCount++;
        }
    }

    metadata.album.photoCount = queriedAlbumPhotoCount;
    return metadata;
}
