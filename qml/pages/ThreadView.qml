import QtQuick 2.2
import Sailfish.Silica 1.0

Page {
    id: commentpage
    allowedOrientations: Orientation.All
    property string content
    property string source: "https://forum.sailfishos.org/t/"
    property string intro
    property int topicid
    property string url
    property string aTitle
    property int posts_count


         function getcomments(){
            var xhr = new XMLHttpRequest;
            xhr.open("GET", source +  topicid + ".json");
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    var data = JSON.parse(xhr.responseText);
                    list.model.clear();

                for (var i=0;i<posts_count;i++) {
                        list.model.append({cooked: data.post_stream.posts[i]["cooked"], username: data.post_stream.posts[i]["username"]});
                }
                }
            }
            xhr.send();
    }






    SilicaListView {
        id: list
        header: PageHeader {
            title: aTitle
            id: pageHeader
        }
        width: parent.width
        height: parent.height
        anchors.top: header.bottom
        VerticalScrollDecorator {}

        ViewPlaceholder {
            id: vplaceholder
            enabled: commodel.count == 0
            text: "Loading..."
            }

        model: ListModel { id: commodel}
          delegate: Item {
            width: list.width
            height: cid.height

            anchors  {
                left: parent.left
                right: parent.right

                }

            Label {
                id:  cid
                text: "<p> <b>" + username + "</b></p><p><i>" + cooked + "</i></p>\n"// + cooked
                textFormat: Text.RichText
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                anchors {
                    leftMargin: Theme.paddingMedium// * indent
                    rightMargin: Theme.paddingSmall
                    left: parent.left
                    right: parent.right
                    }
                onLinkActivated: {
                    var dialog = pageStack.push("OpenLink.qml", {link: link});
                }
                }
            }
        Component.onCompleted: commentpage.getcomments();
    }
}

