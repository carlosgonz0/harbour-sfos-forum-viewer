/*
* This file is part of harbour-sfos-forum-viewer.
*
* MIT License
*
* Copyright (c) 2020 szopin
* Copyright (C) 2020 Mirian Margiani
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import QtQuick 2.2
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0

Page {
    id: commentpage
    allowedOrientations: Orientation.All
    property int likes
    property int post_id: -1
    property int highest_post_number
    property int post_number: -1
    readonly property string source: application.source + "t/" + topicid
    property string loadmore: source + "/posts.json?post_ids[]="
    property string loggedin
    property string raw
    property string topicid
    property string url
    property string aTitle
    property var reply_to
    property int last_post: 0
    property int posts_count
    property bool tclosed
    property bool cooked_hidden
    property bool acted
    property bool can_act
    property bool can_undo

    function getRedirect(link){
        var xhr = new XMLHttpRequest;
        xhr.open("GET", link);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var xhrlocation = xhr.getResponseHeader("location");
                var testa =  /^https:\/\/forum.sailfishos.org\/t\/[\w-]+\/(\d+)\/?(\d+)?$/.exec(xhrlocation);
                pageStack.push("ThreadView.qml", { "topicid":  testa[1]});
            }
        }
        xhr.send();
    }

    function findOP(filter){
        for (var j=0; j < commodel.count; j++){
            if (commodel.get(j).post_number == filter){
                pageStack.push(Qt.resolvedUrl("PostView.qml"), {postid: commodel.get(j).postid, aTitle: "Replied to post", cooked: commodel.get(j).cooked, username: commodel.get(j).username});
            }
        }
    }
    function uncensor(postid, index){
        var xhr3 = new XMLHttpRequest;
        xhr3.open("GET", "https://forum.sailfishos.org/posts/" + postid + "/cooked.json");
        xhr3.onreadystatechange = function() {
            if (xhr3.readyState === XMLHttpRequest.DONE)   var data = JSON.parse(xhr3.responseText);
            list.model.setProperty(index, "cooked", data.cooked);
            list.model.setProperty(index, "cooked_hidden", false);
        }
        xhr3.send();
    }
    function getraw(postid, oper){
        var xhr = new XMLHttpRequest;
        xhr.open("GET", "https://forum.sailfishos.org/posts/" + postid + ".json");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE){   var data = JSON.parse(xhr.responseText);
                raw = data["raw"];
                if (oper == 1) Clipboard.text = raw;
                return raw;
            }
        }
        xhr.send();
    }
    //onRawChanged: Clipboard.text = raw;

    function like(postid, index){
        var xhr4 = new XMLHttpRequest;
        xhr4.open("POST", "https://forum.sailfishos.org/post_actions?id=" + postid + "&post_action_type_id=2&flag_topic=false");
        xhr4.setRequestHeader("User-Api-Key", loggedin.value);
        xhr4.onreadystatechange = function() {
            if (xhr4.readyState === XMLHttpRequest.DONE){
                if(xhr4.statusText !== "OK"){
                    pageStack.completeAnimation();
                    pageStack.push("Error.qml", {errortext: xhr4.responseText});
                } else {
                    var data = JSON.parse(xhr4.responseText);

                    list.model.setProperty(index, "likes", data["actions_summary"][0]["count"]);
                    list.model.setProperty(index, "can_undo", data["actions_summary"][0]["can_undo"]);
                    list.model.setProperty(index, "acted", true);
                }
            }
        }
        xhr4.send();
    }

    function unlike(postid, index){
        var xhr4 = new XMLHttpRequest;
        xhr4.open("DELETE", "https://forum.sailfishos.org/post_actions/" + postid + "?post_action_type_id=2");
        xhr4.setRequestHeader("User-Api-Key", loggedin.value);
        xhr4.onreadystatechange = function() {
            if (xhr4.readyState === XMLHttpRequest.DONE){
                if(xhr4.statusText !== "OK"){
                    pageStack.completeAnimation();
                    pageStack.push("Error.qml", {errortext: xhr4.responseText});
                } else {
                    var data = JSON.parse(xhr4.responseText);

                    list.model.setProperty(index, "likes", list.model.get(index).likes - 1);
                    list.model.setProperty(index, "acted", false);
                }
            }
        }
        xhr4.send();
    }
    function newpost(){
        var dialog = pageStack.push("NewPost.qml", {topicid: topicid});
    }
    function postreply(topicid, post_number, postid, username){

        var dialog = pageStack.push("NewPost.qml", {topicid: topicid, post_number: post_number, postid: postid, username: username});
    }
    function newedit(postid){

        var dialog = pageStack.push("NewPost.qml", {postid: postid});
    }
    function reply(raw, topicid){
        var xhr = new XMLHttpRequest;
        const json = {
            "topic_id": topicid ,
            "raw": raw
        };
        console.log(JSON.stringify(json), raw, topicid);
        xhr.open("POST", "https://forum.sailfishos.org/posts");
        xhr.setRequestHeader("User-Api-Key", loggedin.value);
        xhr.setRequestHeader("Content-Type", 'application/json');
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE){
                if(xhr.statusText !== "OK"){
                    pageStack.completeAnimation();
                    pageStack.push("Error.qml", {errortext: xhr.responseText});
                } else {
                    console.log(xhr.responseText);
                    list.model.clear();
                    commentpage.getcomments();
                }
            }
        }
        xhr.send(JSON.stringify(json));
    }
    function replytopost(raw, topicid, post_number){
        var xhr = new XMLHttpRequest;
        const json = {
            "topic_id": topicid ,
            "raw": raw,
            "reply_to_post_number": post_number
        };
        console.log(JSON.stringify(json), raw, topicid);
        xhr.open("POST", "https://forum.sailfishos.org/posts");
        xhr.setRequestHeader("User-Api-Key", loggedin.value);
        xhr.setRequestHeader("Content-Type", 'application/json');
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE){
                if(xhr.statusText !== "OK"){
                    pageStack.completeAnimation();
                    pageStack.push("Error.qml", {errortext: xhr.responseText});
                } else {
                    console.log(xhr.responseText);
                    list.model.clear();
                    commentpage.getcomments();
                }

            }
        }
        xhr.send(JSON.stringify(json));
    }
    function del(postid, index){
        var xhr = new XMLHttpRequest;
        xhr.open("DELETE", "https://forum.sailfishos.org/posts/" + postid);
        xhr.setRequestHeader("User-Api-Key", loggedin.value);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE){
                if(xhr.statusText !== "OK"){
                    pageStack.completeAnimation();
                    pageStack.push("Error.qml", {errortext: xhr.responseText});
                } else {
                    list.model.setProperty(index, "cooked", "(post withdrawn by author, will be automatically deleted in 24 hours unless flagged)");
                    list.model.setProperty(index, "can_delete", false);
                }
            }
        }
        xhr.send();
    }
    function edit(raw, postid){
        var xhr = new XMLHttpRequest;
        const json = [ { "post": { "raw": raw} } ];
        console.log(JSON.stringify(json));
        xhr.open("PUT", "https://forum.sailfishos.org/posts/" +postid);
        xhr.setRequestHeader("User-Api-Key", loggedin.value);
        xhr.setRequestHeader("Content-Type", 'application/json');
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE){
                if(xhr.statusText !== "OK"){
                    pageStack.completeAnimation();
                    pageStack.push("Error.qml", {errortext: xhr.responseText});
                } else {
                    console.log(xhr.responseText);
                }
            }
        }
        xhr.send(JSON.stringify(json));
    }

    function appendPosts(posts) {
        var posts_length = posts.length;
        for (var i=0;i<posts_length;i++) {
            var post = posts[i];
            var yours =  (loggedin.value == "-1") ? false : post.yours
            var action = post.actions_summary[0];
            likes = (loggedin.value == "-1") ? ((action && action.id === 2)
                                                ? action.count : 0) : (action.count && action.id === 2
                                                                       ? action.count : 0);
            can_undo = (loggedin.value == "-1") ? false : action && action.id === 2 && action.can_undo
                                                  ? action.can_undo : false
            acted = loggedin.value !== "-1" ? (action.id === 2 && action.acted ? action.acted : false) : false;
            list.model.append({
                                  cooked: post.cooked,
                                  username: post.username,
                                  updated_at: post.updated_at,
                                  likes: likes,
                                  acted: acted,
                                  can_undo: can_undo,
                                  yours: yours,
                                  can_edit: post.can_edit,
                                  can_delete: post.can_delete,
                                  created_at: post.created_at,
                                  version: post.version,
                                  postid: post.id,
                                  post_number: post.post_number,
                                  reply_to: post.reply_to_post_number,
                                  last_postid: last_post,
                                  cooked_hidden: post.cooked_hidden
                              });
            last_post = post.post_number;
        }
    }

    function getcomments(){
        var xhr = new XMLHttpRequest;
        xhr.open("GET", source + ".json");
        if (loggedin.value != "-1") xhr.setRequestHeader("User-Api-Key", loggedin.value);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var data = JSON.parse(xhr.responseText);
                tclosed = data.closed;
                if (aTitle == "") aTitle = data.title;
                posts_count = data.posts_count;
                var post_stream = data.post_stream;
                if (posts_count >= 20){
                    var stream = post_stream.stream;
                    for(var j=20;j<posts_count;j++)
                        loadmore += stream[j] + "&post_ids[]="
                }
                var xhr2 = new XMLHttpRequest;
                xhr2.open("GET", loadmore);
                if (loggedin.value != "-1") xhr2.setRequestHeader("User-Api-Key", loggedin.value);

                xhr2.onreadystatechange = function() {
                    if (xhr2.readyState === XMLHttpRequest.DONE) {
                        list.model.clear();

                        appendPosts(post_stream.posts);

                        var data2 = JSON.parse(xhr2.responseText);
                        appendPosts(data2.post_stream.posts)
                    }
                }
                xhr2.send();
            }
        }
        xhr.send();
    }
    ConfigurationValue {
        id: loggedin
        key: "/apps/harbour-sfos-forum-viewer/key"
    }
    SilicaListView {
        id: list
        header: PageHeader {
            id: pageHeader
            title: tclosed ? "🔐" + aTitle : aTitle
            wrapMode: Text.Wrap
        }
        footer: Item {
            width: parent.width
            height: Theme.horizontalPageMargin
        }
        width: parent.width
        height: parent.height
        anchors.top: header.bottom
        VerticalScrollDecorator {}
        PullDownMenu{
            MenuItem {
                text: qsTr("Copy link to clipboard")
                onClicked: Clipboard.text = source
            }
            MenuItem {
                text: qsTr("Open in external browser")
                onClicked: Qt.openUrlExternally(source)
            }
            MenuItem {
                text: qsTr("Open directly")
                onClicked: pageStack.push("webView.qml", {"pageurl": source});

            }
            MenuItem {
                text: qsTr("Search thread")
                onClicked: pageStack.push("SearchPage.qml", {"searchid": topicid, "aTitle": aTitle });

            }
            MenuItem {
                text: qsTr("Post reply")
                visible: loggedin.value != "-1" && !tclosed
                onClicked: newpost();
            }
        }
            PushUpMenu{
                visible: loggedin.value != "-1" && !tclosed
                MenuItem {
                    text: qsTr("Post reply")
                    visible: loggedin.value != "-1" && !tclosed
                    onClicked: newpost();
                }
            }

        BusyIndicator {
            id: vplaceholder
            running: commodel.count == 0
            anchors.centerIn: parent
            size: BusyIndicatorSize.Large
        }

        model: ListModel { id: commodel}
        delegate: ListItem {
            enabled: menu.hasContent
            width: parent.width
            contentHeight: delegateCol.height + Theme.paddingLarge
            anchors.horizontalCenter: parent.horizontalCenter

            Column {
                id: delegateCol
                width: parent.width - 2*Theme.horizontalPageMargin
                height: childrenRect.height
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter
                }
                spacing: Theme.paddingMedium

                Separator {
                    color: Theme.highlightColor
                    width: parent.width
                    horizontalAlignment: Qt.AlignHCenter
                }

                Row {
                    width: parent.width
                    spacing: Theme.paddingSmall

                    Column {
                        width: parent.width - subMetadata.width

                        Label {
                            id: mainMetadata
                            text: username
                            textFormat: Text.RichText
                            truncationMode: TruncationMode.Fade
                            elide: Text.ElideRight
                            width: parent.width
                            font.pixelSize: Theme.fontSizeMedium
                        }
                        Label {
                            visible: likes > 0
                            text: !acted ? likes + "♥" : likes + "💘"
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeSmall
                        }
                    }

                    Column {
                        id: subMetadata
                        Label {
                            text: formatJsonDate(created_at)
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeSmall
                            anchors.right: parent.right
                        }
                        Label {
                            text: (version > 1 && updated_at !== created_at) ?
                                      qsTr("✍️: %1").arg(formatJsonDate(updated_at)) : ""
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeSmall
                            anchors.right: parent.right
                        }
                        Label {
                            text: reply_to >0 && reply_to !== last_postid ?  "💬"  : ""
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeSmall
                            anchors.right: parent.right
                        }
                    }
                }

                Label {
                    text: "<style>" +
                          "a { color: %1 }".arg(Theme.highlightColor) +
                          "</style>" +
                          "<p>" + cooked + "</p>"
                    width: parent.width
                    textFormat: Text.RichText
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontSizeSmall
                    onLinkActivated:{
                        var link1= /^https:\/\/forum.sailfishos.org\/t\/[\w-]+\/?(\d+)?\/?(\d+)?$/.exec(link)
                        if (!link1){
                            pageStack.push("OpenLink.qml", {link: link});
                        } else if (/^https:\/\/forum.sailfishos.org\/t\/([\w-]+)\/?$/.exec(link)){
                            getRedirect(link);
                        }  else {
                            pageStack.push("ThreadView.qml", { "topicid": link1[1], "post_number": link1[2]-1 });
                        }
                    }
                }
            }
            menu: ContextMenu {

                MenuItem{
                    text: qsTr("Copy to clipboard");
                    onClicked: getraw(postid, 1);
                }

                MenuItem {
                    visible: version > 1 && updated_at !== created_at
                    text: qsTr("Revision history")
                    onClicked: pageStack.push(Qt.resolvedUrl("PostView.qml"), {postid: postid, aTitle: aTitle, curRev: version, vmode: 0});
                }
                MenuItem {
                    visible: cooked.indexOf("<code") !== -1
                    text: qsTr("Alternative formatting")
                    onClicked: pageStack.push(Qt.resolvedUrl("PostView.qml"), {postid: postid, aTitle: aTitle, curRev: version, cooked: cooked});
                }
                MenuItem {
                    visible: reply_to > 0 && reply_to !== last_postid
                    text: qsTr("Show replied to post")
                    onClicked: findOP(reply_to);

                }
                MenuItem {
                    visible: cooked_hidden
                    text: qsTr("Uncensor post")
                    onClicked: uncensor(postid, index);
                }
                MenuItem {
                    visible: loggedin.value != "-1" && !acted && !yours
                    text: qsTr("Like")
                    onClicked: like(postid, index);
                }
                MenuItem {
                    visible: loggedin.value != "-1"
                    text: qsTr("Reply")
                    onClicked: postreply(topicid, post_number, postid, username);
                }
                MenuItem {
                    visible: loggedin.value != "-1" && acted && !yours && can_undo
                    text: qsTr("Unlike")
                    onClicked: unlike(postid, index);
                }
                MenuItem {
                    visible: loggedin.value != "-1"  && yours && can_delete
                    text: qsTr("Delete")
                    onClicked: del(postid, index);
                }
                MenuItem {
                    visible: false //loggedin.value != "-1"  && yours && can_edit
                    text: qsTr("Edit")
                    onClicked: newedit(postid);
                }
            }
        }

        Component.onCompleted: commentpage.getcomments();
        onCountChanged: {
            if (post_number < 0) return;
            var comment;

            if (post_id === -1 && post_number >= 0 && post_number !== highest_post_number) {
                for (var j = 0; j < list.count; j++) {
                    comment = list.model.get(j);
                    if (comment && comment.post_number === post_number) {
                        positionViewAtIndex(j + 1, ListView.Beginning);
                    }
                }
            } else if (post_id >= 0) {
                for(var i=post_number - (highest_post_number - posts_count) - 1;i<=post_number;i++){
                    comment = list.model.get(i)
                    if (post_id && comment && comment.postid === post_id){
                        positionViewAtIndex(i, ListView.Beginning);
                    }
                }
            }
        }
    }
}
