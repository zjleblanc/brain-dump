import AppKit
import ImageIO
import SwiftUI

@main
struct BrainDumpApp: App {
    @StateObject private var store = TodoStore()

    init() {
        // Prewarm the emoji scan (~150ms) on a background queue so it's already
        // cached by the time a user opens the list emoji picker, avoiding a
        // one-time stutter during the sheet's slide-up animation.
        DispatchQueue.global(qos: .utility).async {
            _ = AppEmojiPalette.emojis
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MainContentView()
                .environmentObject(store)
        } label: {
            MenuBarLabel()
                .environmentObject(store)
        }
        .menuBarExtraStyle(.window)
    }
}

/// Shows a brain silhouette (matching the Brain Dump app icon's artwork) in
/// the menu bar with a count of active items.
private struct MenuBarLabel: View {
    @EnvironmentObject private var store: TodoStore

    var body: some View {
        HStack(spacing: 3) {
            Image(nsImage: BrainIcon.templateImage)
            if store.activeItemCount > 0 {
                Text("\(store.activeItemCount)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
        }
    }
}

/// A monochrome, line-art brain glyph derived directly from the Brain Dump
/// app icon's artwork — not a hand-drawn abstraction. The source artwork is
/// already a clean, bold-stroke vector design (a thick outer contour ring
/// plus three large crease swirls per hemisphere), so the glyph is just
/// the outer ring plus those internal creases, extracted by their actual
/// drawn colors (the ring's near-white tone and the creases' near-background
/// navy tone) rather than any shape-filling heuristic. The artwork's near-
/// square proportions are padded into an exact square canvas.
///
/// `MenuBarExtra`'s label renders through a private status-item hosting
/// scene (`com.apple.controlcenter.statusitems`) that reliably draws
/// `Image`/`Text` content but ignores `.resizable()`/`.frame()` sizing on an
/// oversized source image (it rendered at the raw PNG's ~300×141pt native
/// size, overflowing the menu bar) and renders a raw SwiftUI `Shape` as
/// blank. To sidestep both quirks, the final menu-bar-sized bitmap is baked
/// once at `templateImage` creation time — decoding the embedded PNG bytes
/// (Base64, to sidestep SPM resource bundling differences between
/// `swift run` and a packaged `.app`) via `CGImageSource` (which reads exact
/// pixel dimensions, ignoring any embedded DPI metadata) and drawing it into
/// a freshly sized `NSImage`, marked `isTemplate = true` — the same
/// mechanism SF Symbols use, which is known to render and auto-tint
/// correctly for light/dark menu bars.
private struct BrainIcon {
    /// Target side length in points for this square glyph. 16pt is Apple's
    /// baseline weight for a circular menu bar glyph, and 22pt is the hard
    /// ceiling for the status item's working area — see
    /// https://bjango.com/articles/designingmenubarextras/. 18pt sits
    /// comfortably between the two.
    static let targetSide: CGFloat = 18

    static let templateImage: NSImage = {
        guard let data = Data(base64Encoded: base64PNG, options: .ignoreUnknownCharacters),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return NSImage()
        }
        let targetSize = CGSize(width: targetSide, height: targetSide)
        let image = NSImage(size: targetSize, flipped: false) { rect in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            context.interpolationQuality = .high
            context.draw(cgImage, in: rect)
            return true
        }
        image.isTemplate = true
        return image
    }()

    private static let base64PNG =
        "iVBORw0KGgoAAAANSUhEUgAAAKAAAACgCAYAAACLz2ctAAAAAXNSR0IArs4c6QAAADhlWElmTU0AKgAAAAgAAYdpAAQAAAAB"
            + "AAAAGgAAAAAAAqACAAQAAAABAAAAoKADAAQAAAABAAAAoAAAAACEJDuzAAAtbklEQVR4Ae2dCbhdRZW2ZR4EAgQIMyGAKDIH"
            + "EWQMAioqqAg4/iiCIoqtbTt0gyLiPP/agDYO0MDvjEwiikIABQdkFghDchOGMM8QELX/973coisrtc89+5x9zr3B8z3Pd3fV"
            + "qqpVtatWrVq1T54nz3nOAIMZGMzAYAYGMzCYgcEMDGZgMAODGRjMwGAGBjMwmIF/lhlY5Fn6ouvyXlPhlnAyNB9xF4IheMUI"
            + "b+L5P7AfWJxONoCObys4GU6CORzLzXAmvAr+Bc6BA4zTGVidcR0Gz4EPQBewXT5G3UvhB6CG0Suo+9/hZXAebHd81vOdzoIH"
            + "Q991gHEyAxsyjq/B22GdBa2q60KfBPVOTUFd6qy7MarG6Lv6zuvBAcZoBpai34/Ae2HVQnUjfxi9X4Erw05hW3Woq5uxVLWd"
            + "i17nwLkYoI8zsAV9XQirFibK/0Hdv2X8e422xl47wrrYnQa2jWOpyjumfIxV9Upy58I5WeiwyEI34uc8Z1/G/F+wlWdykR6F"
            + "j0O9z3Lwbphgfgm4NFwSPnckz6MIY0TjwxOKpQsKD0f0ObjsgkXPSJ4ipV6fD8Jl4H0wwYuTcr3b8tAxt1qv+yl/J/wpXGjQ"
            + "6oX6+RIT6GxV6NOJdvIfgB4xei9jHg3pIPgl6GKV8FeEqY3GtQLUwDS2iOQVH6FAutArQdtV4UMU2H8r/BuFX2xR4QnKfLcn"
            + "oYYlFxshj/mgV/SyIn03PeQa0HcqwXr270ZR71rQum6E9eDNUIN/CN4z8uQxdhgrA3QytoUebVvDyVCPVvIYerP7RrgxzxI0"
            + "pjug7+PEa3h14QK7MC66Y6la5FZG2Mr41K+X0tjcaFX6KSrCeXCjaGS+50SorhKuQTgJ+h5+8onwZHAsQ/By+Fv4RzgbPmvh"
            + "MXcAPBvqAZzQJuiCOHEeV03q0+ir9O1PWYSyqvrqcoyOtapOHbmGOAQfbkiffbsmro1r5Fo9a+DLHALdlXUmuZ26d6NzLvRo"
            + "Gq2+ddz1Hn2j1U3HvvVLdZXn3ngz8qW66tH4DCFMl3R1KvN9mtx4+ThcK9es54a4CJ30Evug/JNw8x504oS5uBNh6T2MdS6C"
            + "F8Ir4W1QY7W+8eam0BBgT2jsV4JGIxZ9+jHfX3XvAe37fPgSGOGxK6qOW+PBS+F06BjvhQl+tH4xnAY3ScLC002oMa5ZKOtW"
            + "dC0KjoE/6lZRv9s7GSfBfFeNljb2ko9Aj1OpEcnY1oWqOsZdjBPhVrAdTKbSp+E9MPZjXs92R0XZu5C/o6LMNlVjfIyyL0I9"
            + "52jwUqQRngZL41PmUWz8GsudC+cvzadz6xwrj3Vb5V1LN+1CAT3BDNjqhSxzYpw4F/4WeDN0Nw/BG6A6nNQb4a0j1PCczCHo"
            + "RMY+bLMn7ATPo9F5MOo0r/csLbBjcUyxjXVtE+XmL4dewDrBvjSaA6NePfVs6HgehWlObyLtb97Oi3M6BJ1j66rHeq6BaxF1"
            + "xrze0LUd13gtoystVP4yvrAv7yS4eN7ISsaUt3GC9RpO2CxY2sHTka8Bu8FSNP5vmPdt2vE55lK/sa51rFt6p1OQrwi7wUY0"
            + "vhiW+tXo9XJedkr9520sd+5dg1nwdugc53Vi2rV9IxyXOIxRtXppX/ZOOBc6SfHluslfgL6JsAksiRINJY4nbYAoj3nj0tJC"
            + "/gz5ErAJ+K4Xwdh3N3nXxw3uGpmu0qUzcK3HFd7MaKqMzwF7DLg7n4RVL9ap3GNnbdgklkfZn2Eck+FAq3fQ+/musd1MZKvD"
            + "JvEClJUMPfZdN+/7Gb/qKFy7UnvXel84LjCNUWgEpYG6IB61BvKl8ijzeHYBEz0eqiYhtbX8dLgGbBLboSwam55bL5H6jk/L"
            + "rJPLHZ+hSZPYAGW/gFWbPu/f+C7Np/FfO21s75rNgk/AXF9Ku+au/ZhCz6OBpUHlT3fnLPjXinLranBO5OFwZ7geXDnjaqSn"
            + "wvdAb4HWz/vI09dTtgVsEj9GWd6HxmSslMvytGXWyWXTyS8Km4LvOATzPvK0m97j+aPw5XBTmOZ0FdK23xseDX8LqwxMnZbp"
            + "9as8rWuvDYwJFqfXs2H+8intTewGGD1IKtfFHwWnwDrYkMqfhlUXnTmUNWmEu6IvegxjpNKiGTeVjLNJ77c7fXg0pnnMnxr+"
            + "d+D2cBHYLjaj4rGwanPrQFzLKiPUBhaDfcdb6DGfgJTW5d8CS57P3flN2O2ucVfrOVOf+VMj3Ag2AS8kV8Fcv8ZfCik8fg0Z"
            + "8roapN6nCbixboO5/pS+EvleXXbyfNqfCJPO/Ola6glLG896h8C+Qlc+C+aDNK230C1raLHM+GM/2BQ0js/C2I/56XBp2ATc"
            + "MHkferqhILNc2bwgP5N8EzAUmQHzcaT0qcibMnLHejD0HZP+9PQ0mwXjiWC5G20N2DccQ09pYPnT46F0IXGA2/RodO+sGMtn"
            + "GurP+DR/Rz28x3AuM61XjBuvqTGcUujPPl2HOsct1dvCS6nlmsV3dG1d4yhPY6Go91iTLvRmcRDe/vR+Ue6x4UWilyhtCGOW"
            + "LRvoVK+dv5Ox1tVBZvl1MF5A3oKsW+yJgmjY9veNbhWP0l6HUQo1XGPXOp8T09qEttFzfJAeYudO/Cyod8jLdOXTYD9Q8hKn"
            + "0XG3HuIAdOTv5LteEWSWXw6jAe6PrBssTuOLYd6/6QvgMrDXeAMdxCO36gRwXNpGT7EE2ksfaB9FrqeLE/UJZP2CMcgdMB+D"
            + "wfPULgfQrgFqlNEAbdsNXkXjqFPv4yWsX/hPOsrn1PR9sBQnehlaCvYM26E5ejkHZFwQjwlvwivBfuLddBYn6+tdDmCsDFDP"
            + "/YvC+xhu9BOr0ZlfFvJ51QZKsaCbZWfYNhZtu+bTFV/Gw2Mhh7cjsdjTj2f+fpLUA8/k+pM4iW40/ByvJrN8LlhI0n4W2TWM"
            + "1Zjs2CDrddbY7kuhE21Ag0xrn4rdNNpI26hjgCrfraBZVzwhyG8m/6Mg60fWsfw0dDSZ/OZBtjBk9STxU9I5yLyB9xun0uGt"
            + "odPlyHsrjtgDQXRGsc4z+ToGOIlWpdjDXRAnyuB/3jO99DfhIkV4NCxsMK6OODcK+pQ35osbWwMszevGyI3H20IdA/RIiB88"
            + "jfvUoXdMcFBnpMwYPH9HnydDxya/C72hLmw4kwH/Jhv0haSVjRVOp+Pc4FxzY0GZw3BHI2wLMZ5r1eh5hUJvmdHdzkbmz1dj"
            + "BY3u7fCL0Am7DhqvLGzwtvsqmI6080j7bXOs4Jr6r2py77YseU/AJWCChvlCmG+eVLbAs44BbrJA66eP2bxzq1wNx3KiHMPf"
            + "4TUmFnI8wfjP6tE76Dicp3ZhvOdmzg3QtXeMHsc5PC3bQh0DzDtOyo1TVk2ZkeeNIR+z6yPYBm4J1bkBFAbX98Ib4J+h39XG"
            + "Ko6k62cV/IViR7gV1DgmQo/Kh6GYAw1Tfg+de0+2Elzbl2YFS5Muxar21xbqGOB6BY0OIOqYUai3IrJXwzfD7eEKcDRoiGdD"
            + "Y7jrR6s8KC/OwC5ID4TO/SrFGv8rfAtJQxVPju/DU+BtMMfteYa0XrT0i0zJWYWm9bJLUf1a6ABzziRvnJXLDiCf4OeZ90F3"
            + "Tl6nTvpx2h4P14JjAd8nH6/vq3fOZaaVtZoLivuGzenJS0McY538nbT/T7guTHgjiVyH76tzyGWmb4LGh43B3ePxGDvywhEn"
            + "3aNV6O26MbzY1xD69oH9xsJmgO9kgh6Ecf46zXvx+AD0a8drg17XPv78aT/aisf8qGj3M4xuNh613jafhN56Ev5Kwo5Phbrw"
            + "jWAVHqVgFrwA/hpeCefCKqxHwQ/goVUVBvLhfx/5LebBk6cKrtGtUOch74OtsBqFX4FnwyWh657g2j8An0qCkaeh2YpB1lX2"
            + "RbTWsnN6g9JN5zJvRKUdkepY/jP4Vrg+zN208cTKcEf4OTgDpnbxeQhl/cLC4gGPZELiPKX8I5QZ170JvgAuD587wtV5Oucf"
            + "g3+EqU3pOY9y1z0vu78gs1ybaQw7oynv1LQv5U6K8lJeT6lHnArbhbv4M9AdG3UaF+4G+4GFwQDfzkTEOTKvsZwAS5/QEC8A"
            + "ncCe8FewpK8ku4W6pSN/D+SN4UA0xc41AuODKI/5y6mzK+wUr6ChR3PUex2ylTpVWqPdeDfAjXkXj8E4P87ZvjXeM69qaHYg"
            + "nAOj3pjXBvzuG+VvQzYq7KgdeKZHaIBLRGHIu/t2gdODvE72F1TeB3rc5/Ao+XAu+CdMG4N9GsZ4y/j6dfCnsBN4uTgJ7gDP"
            + "GkWBY0jfE/OqnmCN4ctoihZupx7DUZ7yH22s96cV7cXDozzp92kAvQ7sJbrxgPv3cmDoNnaLMZnz4pHcFLx8fhPm856ntYOS"
            + "B/5qOwNo1wMuVVBm8FnV/pOUeZFoEueg7MSgcGXybwiyprNOdqdYstOGbbbzUhHX4MfIvtdm+3aq/Y1Kh0JPsxL0gDqCCC85"
            + "jeGXaMqt3rRH4ryC/NfI4icbRI1gXbTEgPd3yAyee4X/g+L83T2erggyy5VZltd1I/YKE1EcY+OnkPlzWy+gQRnP5+9n2kvi"
            + "3QX5echGRdw9pQbWWbZQoOuNMaDHwaegu6YXmIPSi4LirclPDrImsxt1oSz+Tt6FqgWabonETyg5LiFzVS5oMO1F40PQTZZD"
            + "+/AIjvDdRz0BbDwaNL51QyUtf3kY25+P7MJQt+nsT4PCpclvEmRNZuO719G9QZ3KNetuW6jvhSEaSKFaxyLX9rLQ2tNnOahN"
            + "5NAAl8kFpXQ0oFKd1RD6U1wOO3sCev7nOJ1MHEhe3kTao05Pm2PzPNNg2lCiG91TaF86PZoY4gsLSjwiewlPtugA7E+jj+tu"
            + "iDDJwlZoxwD91hYvIcYaep4c3lB77f3sz7jHODDHmnmmwbSbb/0u9K1N217d0ieEcRkS3Rhkvcgac0cvqx0ZC+bw+F0rF5TS"
            + "7Rjg62gYg3wNMJ7vGsasUicNy9xpcbet13AfSd0WJFZImQ6ebtwdO2g3WhPXreQAvBT2GjfQQbz1ags6oByejrvnglJ6NAPc"
            + "jUb/WmjoDog3XY3v8ULdfogMB3qBPVAaw4y6/bysboM26pc2YRvNGqlyP1pmB03GeqWLp7bzqlB3vmwrA9TFfwPGnaaCB2D0"
            + "gDMs6AMcczSKm3rQr5esfRrQOw0dHuVNQgOMHsfPJP34adK+43zrjErOR9vRhirfv5UBHkXD0u3SHaDiaJhXIusHjKviRBv/"
            + "NA0915QGlHqBe00DeqKKO4LAy06vYuHQ1fB/Q5vLDDUMVWJsbp3J8BgTJVQZ4DZUPrTQwKPO3xnj7eYRZNNhP/B8Oonjjjuy"
            + "23Go/93dKsnaH0Y6btisuKPkzEKrHQqyXoh+jdJ45HpiaoDaQsTbEGwfhebjQqY6HycRv+Hoeu+Ba6RK2VML79cR/FTWb0o2"
            + "3bfBs0dnU9gCRfs2pWxEzxUFfTE0KVRpRPQHtHyhoEnb8ISMMFz7GIyX2VhvOL8bf11kDS7nXeRlLjP9AxgvJIh6hhXR7A60"
            + "b78Hfg229WLUawduyvNhfM+U9wLm4qd8eiqzLOXj8zrKPKaagh71LJj6UX8nn3x83/idF9Go0KjOhan/9HwA2Z0FueX7wJZw"
            + "B+UvlZTqbm+HKZ+eHn11B68BfRv+CX4fxuMc0ahw8neBLxq1Zv0KB9EkvV/p2akBquvo+sNp2cKLxwHwjXBiy5rlwk0RXwg9"
            + "2c6Ga8E6MOa8Debz5PzMgdpMLjf9S9jSS29NhZL30616y8kV2tGrYV38Bw1yPafUVdDD+hugu+Tl8/F2Y4DO4Q49HH8d1Z4a"
            + "58P83b5TR8FIXY3fOcn1+D1Sm8llprUtbawS/5eS2OhJZDML8tOQtbRmykv4BsK8D29zfvIYa+hVp8N8bKa9eOWybgxQPTNg"
            + "3VODJo1jdTQ+BPN3m95BLx7htsv1mHZd/XUkyg2ZivDTRumY1SPoonNFKt4GdoIjaZTrGnVXdNJJzTZOYmnzuYu/CPPxtmuA"
            + "1jsZRgNWl8edn03GEnvRef5epn/U4YB2pF00Nn8tuRvGPmYhmwAXgAFirGxeS47yTgdqp35fi/o+Y8EY4gj6jmMy/27ol/y8"
            + "rF0DtI1z+vnQPuk6FvlY4iQ6T2NJz0M7HJAn4flBn/M0G/pM+tOzeBk5rlDR3XtvkHvz1OI7xQo0vBWmwfh0p3gkjAWOoVPf"
            + "KR+P6Z+MDGb/UFbHAF9PW4/2i4OO1Jdz7kWi33g+HT4C0zh8Pgonw06xNw1zfaY9PR8ryH3v+eCX7OthVODR+3iQX0Z+MdgN"
            + "vkLj2Nc3u1HYQdvlaGOfcRzm3c0rQ+EtM69TxwBtK6bAm2CuJ6XPRb4e7Bf8ZGYIkPpPz9O6HMAytDe+Tfp8anylE1Rb0+ae"
            + "wSaknoB5Y9Nep6N3MIbrFpNR8CDM+3Nh/wX2A1vRyYUw7z+lncTVs0E0YYCq0+tEz5/6nEXZXlbqAz5BH6nf9HTud2+g71K8"
            + "7L1C/akvn9qaNvcM3kYqr2DaoNKjMZd7YdgSNoFPoSTXbVpve3ATyit0eNx9GPrbcezb/FVQQ8nRlAGqcxocgqW+/4bco2kt"
            + "2AssidJPw1LfJyNfpIFOd0NHNDY3Xcm5HZT3Fz+NOEhjv2iA1yEzpmkCHoG/h6UJORH52rApaHga9jWw1J+y38CJMKJJA1S3"
            + "Bh6PqnxMt1HupWgSbAqboehXMO8npYeQrwGbwASURC//EDKZ+kvPE/IOLypUuBOZHik18HkKbBIboWwuzPtIaV33x+Bk2Clc"
            + "7H+H18Kkt/T8FuVuiBKaNkD7cHOdC0tjSTJjJ2/KepWqsVHUEn701blUefx5lO3SUkP9wnNokt7BpzakLeUy04ZAw/Aj8BwY"
            + "K8xG5rGQy/0s0TS2RWGp/9SvsaJBs33vAF08d1qORcko2xi+Ah4Jp8O4gZLO9LTfN8FW6IUB2p9BuJ5OI0jjqXrOpM5J8HC4"
            + "C3Tj+r45VyW/OTSWdONeBJ+EVTrvp8x3axpHoTDvUxvSlnKZaede2xu+oXkFzyt48ZgVZJ7tu8JeYApKnbB8DFXpB6ind7x0"
            + "pI3tLhuRtbOY6nVS9ObrwNHQKwNM/e5EQm9Q9b4luRvLOchpuOS6lepH2QzqvRj2AnujNPY3C1kcmzbnug97ldjABboL5nID"
            + "yQ1hr7A0ivVcpXghH0c3ad/rp1BP2i56bYCOYzGoJ24Vo3bz3qntU/RxPNRb9gp6Yec59elTD+ilNpeZHl6HVxYKjBlibGZw"
            + "vALsNYzbjH08IuKAO83rNU+FdQyP6sPohwGmvrwsHQh/A+fBTt83tvMo/jHcHvYaa9JBXDvj2VIc+srFKVivMCKPW3dLDhfR"
            + "F+k1bqCD98DPwz3gPnA7WGfXugPddZfDX8HzRvI8xjUeY3QnjXAznq+H06CfvobjJZ7twvW7HmrMhhvORT/gCfYIXCnrLHnE"
            + "TDScXE8D1NgiVkAwIQi9yfTDAFO3c0h8Z4STeHrBSHQxhuMHnsJ3uBG6Sa4b4S08XdCFFR7H8ig4GfruGuL6cAMo1obLwPug"
            + "XudeOAv+BdpWA4yOBFFPsUhBu15RrxzxDw2wBI1tCbhKVrholu530nhUXtTvjsdJf0OMQ/4S5liKjGvocV1yJHndfqW9IOk8"
            + "1s06dGP8Fa6TyYaTVQaopytZbGw/yI/tDLhO/TyV2nlbN4IX1hzKihukygBXpEEsGxhkPqWDdNUM6JXXCIV+4fCmvwA0stLR"
            + "6pd3XWYO4y7rG1AOMJiBqhkwdIv3B+2pZICLaHwGrxHeZG4PQq1a6x5gMAOtZkCbiheR2cj8RSvicT3abVFK3luwlpzDb1R6"
            + "wX7fLH0ZXfhEKAxy3SB/NzPA8Aw4R14YcwdhyGTw3+8YcXX6XBXmMKRbNheMpGdqgBqUV/VocA5eQ0xQiV7QG3KvsSEd7AB3"
            + "hP6gruH7YsKfcPzsMBNeCy+Cf4R+gvlngp82psFd4FToDdONmqABzoXO05/geSPPXhvkavSjXeXwI3Q8lrU513J4YV08B5xz"
            + "KOQtez3sFRz06+BZ8BGYj2W0tC7+q3BT2DQOQGHev7e5K4LMcmWW5XVt2zR2RuGP4D0w76ud9NW0+ShMm5lk4zgYjXEsQwWZ"
            + "Njc8Dt32jEIFv7ulL9hJ4SeR9QJ6uukw9dPp0x11HFwLNoXxYoCb8UI/g4Yenc5PaueG1VA8upvGl1GY+vGpDWlLucy0NvdM"
            + "yPDzQgWPWo/nvOGZ5JvEMig7Gnos5P10m74VfU15n/FggIfxPh5j3c5LbK8nbdIbatCGRHk/2pC2lMtM/wY+c1ZfTnovBRm0"
            + "znlw2Uy2BWnjMY/IbmEMcwqc1kKRN6e/wFnweuju92eoSfAFcCNYwtoIfwA3h5+AxhsLI4zLj4fvGGXwGqeb7ib4xEhdf4ud"
            + "AifDGN8jGsZ+/HWO9ocez91iIgo2DkocTx6bpuIrU8Ln62C0UI3Phc/lxji7wG6xIQpKx37qazrlB0ED6yroPXeAX4BDMLWN"
            + "z5MoWxJ2igNomOvsVwyo0Tj2vO887frowfaBztPiMMI50ml8DLqR8/Z5ei5l28FuUbKju1FaOuHelHemJ/HzRj4o0/4zmhhY"
            + "fwZZt/g2CmJf5p2kveEisA5WofLn4WOwpPdzdZSFumNhgG6YVsZ3KuVTwzhHy3qSvRNqbKU5+uVoCtooPz7o1nZmB5l9a2s6"
            + "oWfgbtMlxoE52Hgj1UiWgt3gHBrHvr6LLP8nPJ3o34lG1xV029fhnSikzVgY4Kcq3kFv8oYO3yM1M4Q5G8b5vyxV6PC5Au2i"
            + "sWlohgaxr6uQaXPzId5ebKRH0QtGBS+fr2X9jK7auCzp/Wx9FZUtjP8uz3SnPnyXbStbVRf02wB3Yyj+DJrGnZ5XINuyepi1"
            + "SozJfgiTbp8frqVhwcoeqbk+03fBhwvyY5EtgD2QRAW60Jvh30PZueS7hfHbh+ArulVUaF9lhL+m7mKF+q1E/TTACQzkLzCu"
            + "g05gviOr1YDbLHMejLO/BH3HRWGnMGRybvNxazt6P59Rrq0tgOWQ3ALzyqa1Yn/6yuUGlR534xnPY3COPR+3aSe7DvppgO9n"
            + "YHG8zvWudQY8BnV3p8/opAzdSh/LZyHX1oooxR4elaXA9Xzkixe1jB/hgQwlLuifkS0Qf7QYcr8MUO/n4sTxfr7F2MZDkce5"
            + "cxrH7ebPw6xU/pVWg34+hfMqlEUvqML3tVI2DsqWZAyXwPTyPj0SdoXtol8GWIqhPJEM7sczjmBw+fyaNt6+tyDXtjaDLXEy"
            + "pVGhQfEcGM9zFb4Rjmfsy+Di+xxfY8D9MEBjqJ8Xxnl4jXGORdU306k2kM+vNuK9oXSR8vY9KjanRlRqBw/A0pnul+5D4XjF"
            + "MgzsRphP0k3k/S7WDvphgF6aHoT5GO8nv3o7AxyDOoYwR8O/wXzMprURbSXKrTsNzofSzedqavxkvlpPZ1bkobH5bSeH3wSP"
            + "H6EfhJvCFBQdAz8CJ3ah1M1kvJpjPTJeUsYLtmAgxoA5LiZzZy6omd6U+sfBE+ACC19TV159IzKnwY/DxfIC0tqHlyZtJeJH"
            + "CC6Iwqr8xhTEHalFPwVnwZLlW65neQusE+RTfQG8AsmtUJ3yIvhc2CkME5Ku9Gw3dOiHB3STpXGl5wc7fVnarQZnZTq9kbb7"
            + "vlQtwvl/H/RjeBpj/vQWPBuWjl5tSZuqhY9SO16t7dDg0iAz7zymL6V8P1jXaPTI74ZOWNS5FbJOsSUN3Ty5zqPaVNYPA9RL"
            + "5WMz/co2x1eq5txHfeY/C5crNWgh8/R5L/TXi5LOJPNknFOoow1pS7WxFi1KX7FnIi8ZZhpI/jT2+jrcDZbcMuJhePy8Cp4H"
            + "8/Yp/SjydWGn0CPcB5M+n0e1qawfBnhGGJvj267N8ZWqbVvQl979CsqM2deHi8AInYBrvw/8FrwNpratnv+g3k3QZ15PG1Jf"
            + "Ea2+4+kylw+tknt1kAl2VnoRy40XpLe526HxpbtEipWgn362gOvAEjzudf2pTalOO7IYr6zdTqM+1Ynz5zvP66Lvy2irt/v3"
            + "gg5Pg+OhhjEDzoIJjmMDOAW2chipfr72tvVip3PK7Uob2hy6/rVwBLVzSzatJ7onyGeT3x2eG+SxbSf5e9FpTNkt/B5oWJCP"
            + "4QNtKu2HB/xqGJvxb9z8bQ53vmrvJKch5+/dRFoDfwPM43T13g817NjHkchq4//RIiry67ZGmMvPzDS7WL8L5XndOunz0aNn"
            + "bAruwgugR4oeoN0F7ocBrsl4zoHO7Uy4N2wK01B0Dawz91V11fN+uDQUF8G8ruMvXVK0pVpYlNqXwFy5aY/BJ4P8KPI5dMW7"
            + "wRPhHTDqGC3/B9q4u5aATcOxTaiptB8GmIY0hUQ7R1+q3+5zBSq+D3rkjjb/sfwB2pwF3wyXgTm+Tiav/xR5T8RcZlpb0qYW"
            + "QH5W54We5TFGUpEBZjSM6/KGpK2n95LeoKbCHeFW0PhiDaghJNxHYgg6yF9Dj0pjzV7AsT3UC8UN6dT79QIeixrL9+Au0Avf"
            + "i+Bk6JeKpaDw64Z1dTTXwt9C19F8CXHtF6OS9uE852usLWlTesj5UGWAk6il8eRQaVT8D2RDeaWQ1rh+NUKLloTqzQenQfji"
            + "A/R+Bh6hi7NHqEdaFboeaa0NT1yP+2E7iBvGddUmop2oX5tq2wB12WlXkByGR2/0fir0mG0Xera57VYe1OvpDGgoxvSyU3gJ"
            + "eQKmmFA96lWmx0vQlrSpBVDlAdenpu40h/lolN5Sx+JIcxzu3jxeMlbxht6r4xvV4wJ6kzXhFOiJ4unhEXkndD36CT3lPJgb"
            + "4ErkS7ajTV0B50OVAeqeI/R2utYcGt8CbjWv0GB6OXS9FO4Dt4PGkvlN9hHyeuNL4E/gdKjXfjZgFV5iP/gquCX0OMsX2W9v"
            + "br7fQ2/TZ0Bvo73Gg3Sg4Wt0CRqlduUmyeFmaRv/Qc0U86Wnizs7yC8m77nfS3jzOgReC9NY2nleSX1vbt2O74DQr0eMOzmO"
            + "QVmKf1KZbbuBx9ZH4RBMOtt53kr9I2F+QpDtCf6M1nxMGqCOKZeZ/gRsG5+iZlTgLvOanctPbltjZxVfRDM9Wt5n3fTPaL9W"
            + "Z90PtxorA9TT/QnWfd+8/lW032X4LXrzx819Gcz7NB03orJj4AIoHbVWskGER62Kc3TrXXJdMb0vgl/C7WNBzfxrqH8unFyz"
            + "3VhW97PVeXCbLgexOe1/AT1BegHt5JagWO83FGSV2aoYsNTAI3g1uHKpsGHZa9H3Q7hYhV6P44ugO9xLh0fVJnCnkSeP+bAp"
            + "ubPgq+EQHM/Q+E6Dq1QM0tjujzBf+Enkt4VTYIQhzPHQ0+tE2DSc/xw6KfvqCrpLrTun3/TmBdkp5JvG1ii0r7zvlDbA3gN6"
            + "Cy7B29he8GKY2uRP5VVtKSriAKS5Die4VzGggfutob/U9/XI3wUnwRLchAfCGJOl9nqmbk+TUr8/Rpj68PkAvDnIlGtTbaMU"
            + "A6oknu3fb1tjexXdraWYz6/zh8KqkCFqXxKBL5xPTEob1NdBPw3wewwsjTN/fgf5Sm0OelnqfQbGtVLf1VBDbQqGYNHg7fdv"
            + "MB+/6VoG+JGCgrnI4u70KGgSb0NZHPiDyF7RYSel91DfejX09csAt2BMT8D4/v+FbLEa401VDydRMgTnpElEA7wX5XrB+B6f"
            + "rNOp35yigseR+a0tl19Dvk4cSfVKeDQa0+X6Tb+9ssXoBe7QM2HUqYdvF/0ywO8xoDjOC5At0e5AC/WOLugcQtaUF1wRXdEp"
            + "3Y3sPhjf5a3I2oZxVnThGuAcmCu+n7xxSxPYASWxz58ja/fYrRrDJhR4g8/H7cbR4NtBPwzQC4cfdPMxGtx7IekGz6XxDTDX"
            + "a3qfbpRmbdclbXiU67+dvLaSy1zXV8IFULW4t1Hz76G2cZVKc7gD1skFXaT3pK0eK8dxZBx8N7iOxqcHBc8nL8cLXsJAJoXB"
            + "/I687AaP0fjYgoJOQ5qoaiMEywehx348FbWloVBvOFtlgHdRek9oYF0NJDdC85uFep1mNw8N3QS/DbJOs3rSHE7QVrlgjNNb"
            + "F/p3zPlcF6q0JVKPHinHVDLRSPLydtNbhoppvFG3R7IefgFUGaBB5E2htsbmsRW/8ewa6nWS1btuGBrOIO+ngybg7c8jLcf6"
            + "eWaM0y8o9H9lQdaJ6DYazQoN1yDvbblb7BQUOMcaobaSYw6ZB3NBSlcZoEpctIilETwZhNPIrxhkdbPe8oxXcszMM12mDYyj"
            + "F4iT1GUXXTUvGUNTm0+j0KHkMOZcLRd0kNaIdw7tvMWXLjiXI48h3XDTKgO08JLhGvP/0QANOnOsSWb3XNBhOrnv1Dzmk7yT"
            + "p7f3uaFhUwsc1HaU9SaZww1zSy7oMt1qnTtVvQcNVwqNdU6lzXRhqPdMttXALqaWC5fDo1JLjheDQ5A17VH0ik3Bnfkv8C/Q"
            + "o+AMeCIcL/giA3HDO7ca3wehXxiaQpOb2TFpB+8Ng3Pshmfx64Inzx9C3bayGtQF0MHndGK8oOQybz67wE6hZ70R5jov6FRZ"
            + "i3bLUObRUQf9+AzjeFzULaEnSpNQr+FUPre3k+8mbHp90KduTxQ/Quf9mD4fVjqnVh7QxqfCCK/d84JQb/VZGK0/VKvM6rpn"
            + "h9JVyTt5TcJxx6N4NP3OQ0Q8ASwvyUpto66UN1a7Et6RBA09jcmiUetEYkzcbneu/8dDZd9TnfFIttrpsHIeWhmgjb3CqziH"
            + "V2wH4cfdHNuT+VAuqJF2gDHmWR/ZWjV09Kqq3jmHu3liLhhJO9a40ycX6vVbtDEdRsNwrjX4TnA0jTYLDR8jr7OI9uTlx3Cn"
            + "ErFBrKi3ODkKyburdLnRso9E9krYCS4LjQxmpwbZWGRfGDo1zvEoj9ADxkWdEiuNQd45jOt8VYfjOJB2xtI5fO8HYSm00fhm"
            + "55U7SWvtpR/JNcC7oEaYU9kOsC62oYGBbK7r23WV9KC+p0A+Jj2/GzOXmb4P6gly+aXk4+Ij6it+RW/5mEzv2cEI3kobQ6Wo"
            + "y++MpdhPm9kKNoJvoCV2bN7ONcRY5k1uX1gHHnXXw1yXxhzjlzo6u627KgruhPmYPFb8FJXLTBuqxA3p3KwLxwqb0LEbJh/r"
            + "HPKeYHXwDiqXjM958EKT60/p0slZp8/56vrRUmNLytNTj+ULeSwlWXoq+yys87KfK+g5AtlYYT86Tu+Tns5D1fuWFuOwsRo8"
            + "/fp5J407Pb9VYzwTqXtcQYe6NMiZ0C8gSXd6uhnXh41CF5w6yJ8uxo2wdExb7xqoN2znRmu8FfXogVaHY4Gz6TS+61CQ5eWW"
            + "ReP8E7IlYL8xhQ7j0ajD2KGNgXjJfBecAfP3S2nX6AboV4Uky5/vRd44vOH9AOYdpbRX+pthyU2nOldQ7sBG2xknUie1Sc86"
            + "u5bmjWBHtERjMrS4B6Zxxadl1ony1yDrN35Ih3Ec57UYhJ/SNoUfgzEUyvV40XKtXfNcntJnIF8c9gQrodVvVamz/Kkr9hvW"
            + "IxXlqa5x0e/h16GxhQu9dcaDSKsr1ffpzvU47BecQBcrH4PpquM31dNgrZPy6Xk1Mr1Kv+Acpr7z55eR53PtyfSv8ASog4in"
            + "T97WtGs3BOP6pHrXUbYa7Cl07XNg6jQ+DcSNhVyMWNZOvurl9C4vgf3AEXQSx+oN1wtIlMe8dUqb8GvI+wE3dKl/x+knkzje"
            + "dvKuiaGQN32dQamNx/1U2BfsRC92WBqIMm9eGqmDrhpwVdtWco2710b4MvqIoYTvcCus2hz5mK2rF4yLrfwQ2EtMQ3m8iedj"
            + "q5v2HTS6W2CVUatTW9gZ9hXb0VurWCEN3guKhqgHqTsBpfpOyJthL7AHStUf+3X8Hj9R7pEVjdU61jUcifU9FQ6GvYDhTNWl"
            + "II5jtLx6fGediB+Z3TxVbazTd+Ojz2FM4e+FsGpwSe6C6EFuhkPQa7ov6YtpqKleeipzsR4eeSZ5elp+PFwVNoX3oqgUWLsA"
            + "pbjOsXwBHgPTuPKnl5HSptOLfhwuDpvAOij5Dsz7Tmnn0NPIZ9U8uwauhWtkmKNB6UXNl9ok3T69D2wIxxTL0/txMB9YVdqX"
            + "1ZWnF51BWk9xLbxqhDN5uuA+pXWqguObKHsLXBp2CjfRf8PSmL3xORbHHcuVT4QToOOM5f9A5mKqI5aZ9xOPF4JOsRIN3wPt"
            + "o6Rfz5zmdy5p43LHmebZOXfuraMOj9HkFEr6osw1XxmOG+zNSHy5ONB28u5QF0rGOEuv5AQ5OVW6rqHsA3Aj2C7cuV+BpSPX"
            + "fuzPxXFspX41/IT9SZSMVNktsEqHHvJYOBX6mWs0LEaFLeGn4BAsjSsfu3OX13Fu0zxXjSmvX0pfj459YSNo56XrdLQcld8H"
            + "D4Nr1Wk4Sl0X0l28IrSPKrigv4fToceDx6BHvxO5GnRMLuBOcAe4AizhEYQeXXqZknf9LvKDoXoTTiChLMJF92a8FKzqT6O4"
            + "Av4OXgZnwxxTyLwYvgRuBpeAVXiIgvuh77pkVaUO5HrQb0I3jO8zrrE6ozsCultKu6hTWfrE44K1q8PJckGearONHtEAPHri"
            + "1J8GMgFGuDEugale/rRvdVZ527xup2n7uA06Rx7/neqJ7VxD19I1XejwXEb8cujO8SjSk8UXrJv3WHGiNaoqI6mr0/p6vSF4"
            + "L6xqb9y0LqyCZXreqvbqHi2cqGpbJXcOnAvjOb12Vb125Rqva+WauXauYc/Q9BHcaqDLU7gx3BQafG8OJ0KPxggN1XinVJbq"
            + "OtkajTt/VbgM7ATqmQddSI/4Kj0e5a+Bl8NW0AjPhFtUVPJy4DHp3DsnS8NOkPRoWBqJHrgKD1LwBFy0UMGx3AP1dL7bZSNp"
            + "57bn6KcBll7GWMZFiHAXapzHwT1jYcg/TN7YT0M0zpLLQnWX3k/j9gjX6DQ+oaG3MoSrKH8dnAnbgUZ4OtyqRWUNSM+1OHSz"
            + "2b8xm/kIjcxx2yaN23orwdE81B+ocxCcC0vzoT45JigNaEwGUtGp3uho+AFYWpi8mUarQbnbhYt513Dqf/+sQlLjWwFqqC76"
            + "aHrPoM67oQtYB26g4+F+ozTSsDSAtIlcE4/qtaEG+jicBPVgzocG51OjbQU9+jfgJ6CbdIAuZmB32no8tBvHpHouQk6NNJWN"
            + "9nyIuh+CrW6cFLeER96/QXWN1l8qd4yO2afGaTqVtfu8gjbO2QANzoDH6vuhQXy7C9FpvZ/Tx1awKWyGop/BOhugk7E7Nx+B"
            + "ox3LVBmg0xkwXnOSr4GdLFJVG73NOfC1sFfYDcUat31VjaMT+bXoc06cmwH6NAPGQXvBk2A3XnEW7f3k4EfefsG+vgqvh50a"
            + "42209d1fAz0dFkoY8D4bMIGX8PPODtCjc90RGqivCoVx2DzoJ4dboHHSJSNPy8YCXoI8nl8Kp8INoOM17vQSIxyvRnonvB06"
            + "7kvhn+F9cKHGs8UAS4uwPMLF4RrQ93SxHoPeKl3Q8Qg3jN7MG/zq0OPY27cXEcduDDnAYAYGMzCYgcEMDGZgMAODGRjMwGAG"
            + "BjMwmIHBDHQ6A/8fhPfIiQZ6XGoAAAAASUVORK5CYII="
}
