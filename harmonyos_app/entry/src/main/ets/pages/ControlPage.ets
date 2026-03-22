import { ConnectionType } from '../constants/BLEConstants'

@Component
export struct ControlPage {
  @StorageLink('connectionType') connectionType: ConnectionType = ConnectionType.None
  @StorageLink('connectedDeviceName') connectedDeviceName: string = ''

  build() {
    Column() {
      // 顶部信息栏 - 只显示状态
      Row() {
        if (this.connectionType === ConnectionType.None) {
          Row() {
            Image($r('app.media.ic_public_link'))
              .width(18)
              .height(18)
              .margin({ right: 6 })
            Text('未连接')
              .fontSize(14)
              .fontColor('#333333')
          }
          .height(30)
          .padding({ left: 12, right: 12 })
          .borderRadius(15)
          .backgroundColor('#F5F5F5')
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
        } else {
          Row() {
            Image(this.connectionType === ConnectionType.BLE ?
              $r('app.media.ic_public_bluetooth') : $r('app.media.ic_public_starflash'))
              .width(18)
              .height(18)
              .margin({ right: 6 })
            Text('已连接')
              .fontSize(14)
              .fontColor('#333333')
          }
          .height(30)
          .padding({ left: 12, right: 12 })
          .borderRadius(15)
          .backgroundColor('#E8E8E8')
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
        }
      }
      .width('100%')
      .height(50)
      .padding({ left: 16 })
      .backgroundColor('#FFFFFF')
      .alignItems(VerticalAlign.Center)

      // 内容区域
      Column() {
        Text($r('app.string.Control'))
          .fontSize(50)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
