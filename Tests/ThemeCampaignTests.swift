import XCTest
import SwiftUI
@testable import KomorebiStudy
@MainActor final class ThemeCampaignTests: XCTestCase {
    private var calendar: Calendar { var c=Calendar(identifier:.gregorian);c.timeZone=TimeZone(identifier:"Europe/Rome")!;return c }
    private func date(_ year:Int,_ month:Int,_ day:Int)->Date { calendar.date(from:DateComponents(year:year,month:month,day:day,hour:12))! }
    func testInclusiveWindowAndAnnualIdentity() {
        let settings=UserSettings()
        for (month,day,expected) in [(10,14,false),(10,15,true),(11,1,true),(11,2,false)] {
            XCTAssertEqual(!ThemeCampaign.available(settings:settings,date:date(2026,month,day),calendar:calendar).isEmpty,expected)
        }
        XCTAssertEqual(ThemeCampaign.available(settings:settings,date:date(2026,10,15),calendar:calendar).first?.id,"halloween-2026")
        let crossing=ThemeSuggestionWindow(startMonth:12,startDay:20,endMonth:1,endDay:10)
        XCTAssertTrue(crossing.contains(date(2027,1,1),calendar:calendar));XCTAssertEqual(crossing.campaignYear(date(2027,1,1),calendar:calendar),2026)
    }
    func testDismissAndSelectionPersistWithoutAutomaticThemeChange() throws {
        let suite="KomorebiTests.Campaign.\(UUID())";let defaults=UserDefaults(suiteName:suite)!;defer{defaults.removePersistentDomain(forName:suite)}
        let store=try StudyStore(inMemory:true,defaults:defaults);store.now=date(2026,10,23)
        let campaign=try XCTUnwrap(ThemeCampaign.available(settings:store.settings,date:store.now,calendar:calendar).first)
        store.dismissThemeCampaign(campaign.id)
        XCTAssertNil(store.settings.themeID)
        XCTAssertTrue(ThemeCampaign.available(settings:store.settings,date:store.now,calendar:calendar).isEmpty)
        let reopened=try StudyStore(inMemory:true,defaults:defaults)
        XCTAssertTrue(ThemeCampaign.available(settings:reopened.settings,date:date(2026,10,23),calendar:calendar).isEmpty)
        XCTAssertFalse(ThemeCampaign.available(settings:reopened.settings,date:date(2027,10,23),calendar:calendar).isEmpty)
        store.selectTheme(HalloweenTheme.package.id)
        XCTAssertEqual(store.settings.themeID,HalloweenTheme.package.id)
        store.selectTheme(ThemeRegistry.defaultPackage.id)
        XCTAssertTrue(ThemeCampaign.available(settings:store.settings,date:store.now,calendar:calendar).isEmpty)
    }
    func testActiveThemeNeverSuggestsItselfAndOldPreferencesDecode() throws {
        var settings=UserSettings();settings.themeID=HalloweenTheme.package.id
        XCTAssertTrue(ThemeCampaign.available(settings:settings,date:date(2026,10,23),calendar:calendar).isEmpty)
        var json=try JSONSerialization.jsonObject(with:JSONEncoder().encode(settings)) as! [String:Any];json.removeValue(forKey:"dismissedThemeCampaigns")
        let restored=try JSONDecoder().decode(UserSettings.self,from:JSONSerialization.data(withJSONObject:json))
        XCTAssertNil(restored.dismissedThemeCampaigns)
    }
}
