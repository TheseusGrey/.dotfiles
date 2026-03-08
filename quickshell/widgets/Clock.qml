import QtQuick
import qs.config
import qs.components

StyledText {
  text: Time.time + " | " + Time.date

  font {
    pointSize: Appearance.fontSize
    family: Appearance.fontFamily
  }
}
