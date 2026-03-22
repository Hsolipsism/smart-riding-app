import { ConnectionPage } from './ConnectionPage'
import { DebugPage } from './DebugPage'

@Component
export struct SettingsPage {
  @Provide('pageInfos') pageInfos: NavPathStack = new NavPathStack()

  build() {
    Navigation(this.pageInfos) {
      Column() {
        // 设置标题
        Text('设置')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .width('100%')
          .padding({ left: 16, top: 20, bottom: 20 })

        // 连接管理按钮
        Row() {
          Image($r('app.media.ic_public_view_list_filled'))
            .width(24)
            .height(24)
          Text('连接管理')
            .fontSize(16)
            .fontColor('#333333')
            .margin({ left: 12 })
          Blank()
          Text('>')
            .fontSize(18)
            .fontColor('#999999')
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .onClick(() => {
          this.pageInfos.pushPathByName('ConnectionPage', null, true)
        })

        Divider()

        // 调试管理按钮
        Row() {
          Image($r('app.media.ic_public_debug'))
            .width(24)
            .height(24)
          Text('调试管理')
            .fontSize(16)
            .fontColor('#333333')
            .margin({ left: 12 })
          Blank()
          Text('>')
            .fontSize(18)
            .fontColor('#999999')
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .onClick(() => {
          this.pageInfos.pushPathByName('DebugPage', null, true)
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
    }
    .navDestination(this.PageMap)
  }

  @Builder
  PageMap(name: string) {
    if (name === 'ConnectionPage') {
      NavDestination() {
        ConnectionPage()
      }
      .title('连接管理')
      .onBackPressed(() => {
        this.pageInfos.pop()
        return true
      })
    }
    if (name === 'DebugPage') {
      NavDestination() {
        DebugPage()
      }
      .title('调试管理')
      .onBackPressed(() => {
        this.pageInfos.pop()
        return true
      })
    }
  }
}
