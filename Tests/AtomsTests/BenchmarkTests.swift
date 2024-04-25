import XCTest

@testable import Atoms

struct BenchmarkTestAtom1: StateAtom, Hashable {
    func defaultValue(context: Context) -> Int {
        0
    }
}

struct BenchmarkTestAtom2: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom1())
    }
}

struct BenchmarkTestAtom3: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom2())
    }
}

struct BenchmarkTestAtom4: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom3())
    }
}

struct BenchmarkTestAtom5: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom4())
    }
}

struct BenchmarkTestAtom6: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom5())
    }
}

struct BenchmarkTestAtom7: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom6())
    }
}

struct BenchmarkTestAtom8: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom7())
    }
}

struct BenchmarkTestAtom9: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom8())
    }
}

struct BenchmarkTestAtom10: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom9())
    }
}

struct BenchmarkTestAtom11: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom10())
    }
}

struct BenchmarkTestAtom12: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom11())
    }
}

struct BenchmarkTestAtom13: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom12())
    }
}

struct BenchmarkTestAtom14: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom13())
    }
}

struct BenchmarkTestAtom15: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom14())
    }
}

struct BenchmarkTestAtom16: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom15())
    }
}

struct BenchmarkTestAtom17: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom16())
    }
}

struct BenchmarkTestAtom18: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom17())
    }
}

struct BenchmarkTestAtom19: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom18())
    }
}

struct BenchmarkTestAtom20: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom19())
    }
}

struct BenchmarkTestAtom21: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom20())
    }
}

struct BenchmarkTestAtom22: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom21())
    }
}

struct BenchmarkTestAtom23: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom22())
    }
}

struct BenchmarkTestAtom24: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom23())
    }
}

struct BenchmarkTestAtom25: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom24())
    }
}

struct BenchmarkTestAtom26: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom25())
    }
}

struct BenchmarkTestAtom27: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom26())
    }
}

struct BenchmarkTestAtom28: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom27())
    }
}

struct BenchmarkTestAtom29: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom28())
    }
}

struct BenchmarkTestAtom30: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom29())
    }
}

struct BenchmarkTestAtom31: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom30())
    }
}

struct BenchmarkTestAtom32: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom31())
    }
}

struct BenchmarkTestAtom33: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom32())
    }
}

struct BenchmarkTestAtom34: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom33())
    }
}

struct BenchmarkTestAtom35: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom34())
    }
}

struct BenchmarkTestAtom36: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom35())
    }
}

struct BenchmarkTestAtom37: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom36())
    }
}

struct BenchmarkTestAtom38: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom37())
    }
}

struct BenchmarkTestAtom39: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom38())
    }
}

struct BenchmarkTestAtom40: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom39())
    }
}

struct BenchmarkTestAtom41: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom40())
    }
}

struct BenchmarkTestAtom42: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom41())
    }
}

struct BenchmarkTestAtom43: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom42())
    }
}

struct BenchmarkTestAtom44: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom43())
    }
}

struct BenchmarkTestAtom45: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom44())
    }
}

struct BenchmarkTestAtom46: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom45())
    }
}

struct BenchmarkTestAtom47: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom46())
    }
}

struct BenchmarkTestAtom48: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom47())
    }
}

struct BenchmarkTestAtom49: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom48())
    }
}

struct BenchmarkTestAtom50: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom49())
    }
}

struct BenchmarkTestAtom51: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom50())
    }
}

struct BenchmarkTestAtom52: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom51())
    }
}

struct BenchmarkTestAtom53: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom52())
    }
}

struct BenchmarkTestAtom54: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom53())
    }
}

struct BenchmarkTestAtom55: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom54())
    }
}

struct BenchmarkTestAtom56: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom55())
    }
}

struct BenchmarkTestAtom57: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom56())
    }
}

struct BenchmarkTestAtom58: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom57())
    }
}

struct BenchmarkTestAtom59: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom58())
    }
}

struct BenchmarkTestAtom60: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom59())
    }
}

struct BenchmarkTestAtom61: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom60())
    }
}

struct BenchmarkTestAtom62: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom61())
    }
}

struct BenchmarkTestAtom63: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom62())
    }
}

struct BenchmarkTestAtom64: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom63())
    }
}

struct BenchmarkTestAtom65: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom64())
    }
}

struct BenchmarkTestAtom66: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom65())
    }
}

struct BenchmarkTestAtom67: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom66())
    }
}

struct BenchmarkTestAtom68: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom67())
    }
}

struct BenchmarkTestAtom69: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom68())
    }
}

struct BenchmarkTestAtom70: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom69())
    }
}

struct BenchmarkTestAtom71: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom70())
    }
}

struct BenchmarkTestAtom72: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom71())
    }
}

struct BenchmarkTestAtom73: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom72())
    }
}

struct BenchmarkTestAtom74: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom73())
    }
}

struct BenchmarkTestAtom75: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom74())
    }
}

struct BenchmarkTestAtom76: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom75())
    }
}

struct BenchmarkTestAtom77: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom76())
    }
}

struct BenchmarkTestAtom78: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom77())
    }
}

struct BenchmarkTestAtom79: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom78())
    }
}

struct BenchmarkTestAtom80: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom79())
    }
}

struct BenchmarkTestAtom81: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom80())
    }
}

struct BenchmarkTestAtom82: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom81())
    }
}

struct BenchmarkTestAtom83: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom82())
    }
}

struct BenchmarkTestAtom84: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom83())
    }
}

struct BenchmarkTestAtom85: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom84())
    }
}

struct BenchmarkTestAtom86: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom85())
    }
}

struct BenchmarkTestAtom87: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom86())
    }
}

struct BenchmarkTestAtom88: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom87())
    }
}

struct BenchmarkTestAtom89: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom88())
    }
}

struct BenchmarkTestAtom90: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom89())
    }
}

struct BenchmarkTestAtom91: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom90())
    }
}

struct BenchmarkTestAtom92: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom91())
    }
}

struct BenchmarkTestAtom93: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom92())
    }
}

struct BenchmarkTestAtom94: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom93())
    }
}

struct BenchmarkTestAtom95: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom94())
    }
}

struct BenchmarkTestAtom96: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom95())
    }
}

struct BenchmarkTestAtom97: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom96())
    }
}

struct BenchmarkTestAtom98: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom97())
    }
}

struct BenchmarkTestAtom99: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom98())
    }
}

struct BenchmarkTestAtom100: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom99())
    }
}

struct BenchmarkTestAtom101: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom50())
    }
}

struct BenchmarkTestAtom102: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom101())
    }
}

struct BenchmarkTestAtom103: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom102())
    }
}

struct BenchmarkTestAtom104: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom103())
    }
}

struct BenchmarkTestAtom105: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom104())
    }
}

struct BenchmarkTestAtom106: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom105())
    }
}

struct BenchmarkTestAtom107: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom106())
    }
}

struct BenchmarkTestAtom108: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom107())
    }
}

struct BenchmarkTestAtom109: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom108())
    }
}

struct BenchmarkTestAtom110: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom109())
    }
}

struct BenchmarkTestAtom111: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom110())
    }
}

struct BenchmarkTestAtom112: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom111())
    }
}

struct BenchmarkTestAtom113: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom112())
    }
}

struct BenchmarkTestAtom114: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom113())
    }
}

struct BenchmarkTestAtom115: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom114())
    }
}

struct BenchmarkTestAtom116: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom115())
    }
}

struct BenchmarkTestAtom117: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom116())
    }
}

struct BenchmarkTestAtom118: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom117())
    }
}

struct BenchmarkTestAtom119: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom118())
    }
}

struct BenchmarkTestAtom120: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom119())
    }
}

struct BenchmarkTestAtom121: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom120())
    }
}

struct BenchmarkTestAtom122: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom121())
    }
}

struct BenchmarkTestAtom123: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom122())
    }
}

struct BenchmarkTestAtom124: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom123())
    }
}

struct BenchmarkTestAtom125: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom124())
    }
}

struct BenchmarkTestAtom126: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom125())
    }
}

struct BenchmarkTestAtom127: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom126())
    }
}

struct BenchmarkTestAtom128: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom127())
    }
}

struct BenchmarkTestAtom129: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom128())
    }
}

struct BenchmarkTestAtom130: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom129())
    }
}

struct BenchmarkTestAtom131: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom130())
    }
}

struct BenchmarkTestAtom132: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom131())
    }
}

struct BenchmarkTestAtom133: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom132())
    }
}

struct BenchmarkTestAtom134: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom133())
    }
}

struct BenchmarkTestAtom135: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom134())
    }
}

struct BenchmarkTestAtom136: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom135())
    }
}

struct BenchmarkTestAtom137: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom136())
    }
}

struct BenchmarkTestAtom138: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom137())
    }
}

struct BenchmarkTestAtom139: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom138())
    }
}

struct BenchmarkTestAtom140: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom139())
    }
}

struct BenchmarkTestAtom141: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom140())
    }
}

struct BenchmarkTestAtom142: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom141())
    }
}

struct BenchmarkTestAtom143: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom142())
    }
}

struct BenchmarkTestAtom144: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom143())
    }
}

struct BenchmarkTestAtom145: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom144())
    }
}

struct BenchmarkTestAtom146: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom145())
    }
}

struct BenchmarkTestAtom147: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom146())
    }
}

struct BenchmarkTestAtom148: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom147())
    }
}

struct BenchmarkTestAtom149: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom148())
    }
}

struct BenchmarkTestAtom150: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom149())
    }
}

struct BenchmarkTestAtom151: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom150())
    }
}

struct BenchmarkTestAtom152: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom151())
    }
}

struct BenchmarkTestAtom153: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom152())
    }
}

struct BenchmarkTestAtom154: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom153())
    }
}

struct BenchmarkTestAtom155: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom154())
    }
}

struct BenchmarkTestAtom156: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom155())
    }
}

struct BenchmarkTestAtom157: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom156())
    }
}

struct BenchmarkTestAtom158: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom157())
    }
}

struct BenchmarkTestAtom159: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom158())
    }
}

struct BenchmarkTestAtom160: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom159())
    }
}

struct BenchmarkTestAtom161: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom160())
    }
}

struct BenchmarkTestAtom162: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom161())
    }
}

struct BenchmarkTestAtom163: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom162())
    }
}

struct BenchmarkTestAtom164: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom163())
    }
}

struct BenchmarkTestAtom165: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom164())
    }
}

struct BenchmarkTestAtom166: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom165())
    }
}

struct BenchmarkTestAtom167: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom166())
    }
}

struct BenchmarkTestAtom168: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom167())
    }
}

struct BenchmarkTestAtom169: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom168())
    }
}

struct BenchmarkTestAtom170: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom169())
    }
}

struct BenchmarkTestAtom171: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom170())
    }
}

struct BenchmarkTestAtom172: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom171())
    }
}

struct BenchmarkTestAtom173: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom172())
    }
}

struct BenchmarkTestAtom174: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom173())
    }
}

struct BenchmarkTestAtom175: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom174())
    }
}

struct BenchmarkTestAtom176: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom175())
    }
}

struct BenchmarkTestAtom177: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom176())
    }
}

struct BenchmarkTestAtom178: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom177())
    }
}

struct BenchmarkTestAtom179: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom178())
    }
}

struct BenchmarkTestAtom180: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom179())
    }
}

struct BenchmarkTestAtom181: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom180())
    }
}

struct BenchmarkTestAtom182: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom181())
    }
}

struct BenchmarkTestAtom183: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom182())
    }
}

struct BenchmarkTestAtom184: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom183())
    }
}

struct BenchmarkTestAtom185: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom184())
    }
}

struct BenchmarkTestAtom186: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom185())
    }
}

struct BenchmarkTestAtom187: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom186())
    }
}

struct BenchmarkTestAtom188: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom187())
    }
}

struct BenchmarkTestAtom189: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom188())
    }
}

struct BenchmarkTestAtom190: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom189())
    }
}

struct BenchmarkTestAtom191: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom190())
    }
}

struct BenchmarkTestAtom192: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom191())
    }
}

struct BenchmarkTestAtom193: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom192())
    }
}

struct BenchmarkTestAtom194: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom193())
    }
}

struct BenchmarkTestAtom195: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom194())
    }
}

struct BenchmarkTestAtom196: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom195())
    }
}

struct BenchmarkTestAtom197: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom196())
    }
}

struct BenchmarkTestAtom198: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom197())
    }
}

struct BenchmarkTestAtom199: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom198())
    }
}

struct BenchmarkTestAtom200: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        context.watch(BenchmarkTestAtom199())
    }
}

struct BenchmarkTestAtom: ValueAtom, Hashable {
    func value(context: Context) -> Int {
        let value1 = context.watch(BenchmarkTestAtom1())
        let value2 = context.watch(BenchmarkTestAtom50())
        let value3 = context.watch(BenchmarkTestAtom150())
        let value4 = context.watch(BenchmarkTestAtom200())
        return value1 + value2 + value3 + value4
    }
}

final class BenchmarkTests: XCTestCase {
    @MainActor
    func testBenchmark() {
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            let context = AtomTestContext()

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 0)

            context[BenchmarkTestAtom1()] = 1

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 4)

            context[BenchmarkTestAtom1()] = 2

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 8)

            context[BenchmarkTestAtom1()] = 3

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 12)

            context[BenchmarkTestAtom1()] = 4

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 16)

            context[BenchmarkTestAtom1()] = 5

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 20)

            context[BenchmarkTestAtom1()] = 6

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 24)

            context[BenchmarkTestAtom1()] = 7

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 28)

            context[BenchmarkTestAtom1()] = 8

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 32)

            context[BenchmarkTestAtom1()] = 9

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 36)

            context[BenchmarkTestAtom1()] = 10

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 40)

            context[BenchmarkTestAtom1()] = 11

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 44)

            context[BenchmarkTestAtom1()] = 12

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 48)

            context[BenchmarkTestAtom1()] = 13

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 52)

            context[BenchmarkTestAtom1()] = 14

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 56)

            context[BenchmarkTestAtom1()] = 15

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 60)

            context[BenchmarkTestAtom1()] = 16

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 64)

            context[BenchmarkTestAtom1()] = 17

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 68)

            context[BenchmarkTestAtom1()] = 18

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 72)

            context[BenchmarkTestAtom1()] = 19

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 76)

            context[BenchmarkTestAtom1()] = 20

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 80)

            context[BenchmarkTestAtom1()] = 21

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 84)

            context[BenchmarkTestAtom1()] = 22

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 88)

            context[BenchmarkTestAtom1()] = 23

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 92)

            context[BenchmarkTestAtom1()] = 24

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 96)

            context[BenchmarkTestAtom1()] = 25

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 100)

            context[BenchmarkTestAtom1()] = 26

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 104)

            context[BenchmarkTestAtom1()] = 27

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 108)

            context[BenchmarkTestAtom1()] = 28

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 112)

            context[BenchmarkTestAtom1()] = 29

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 116)

            context[BenchmarkTestAtom1()] = 30

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 120)

            context[BenchmarkTestAtom1()] = 31

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 124)

            context[BenchmarkTestAtom1()] = 32

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 128)

            context[BenchmarkTestAtom1()] = 33

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 132)

            context[BenchmarkTestAtom1()] = 34

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 136)

            context[BenchmarkTestAtom1()] = 35

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 140)

            context[BenchmarkTestAtom1()] = 36

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 144)

            context[BenchmarkTestAtom1()] = 37

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 148)

            context[BenchmarkTestAtom1()] = 38

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 152)

            context[BenchmarkTestAtom1()] = 39

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 156)

            context[BenchmarkTestAtom1()] = 40

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 160)

            context[BenchmarkTestAtom1()] = 41

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 164)

            context[BenchmarkTestAtom1()] = 42

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 168)

            context[BenchmarkTestAtom1()] = 43

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 172)

            context[BenchmarkTestAtom1()] = 44

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 176)

            context[BenchmarkTestAtom1()] = 45

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 180)

            context[BenchmarkTestAtom1()] = 46

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 184)

            context[BenchmarkTestAtom1()] = 47

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 188)

            context[BenchmarkTestAtom1()] = 48

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 192)

            context[BenchmarkTestAtom1()] = 49

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 196)

            context[BenchmarkTestAtom1()] = 50

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 200)

            context[BenchmarkTestAtom1()] = 51

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 204)

            context[BenchmarkTestAtom1()] = 52

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 208)

            context[BenchmarkTestAtom1()] = 53

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 212)

            context[BenchmarkTestAtom1()] = 54

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 216)

            context[BenchmarkTestAtom1()] = 55

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 220)

            context[BenchmarkTestAtom1()] = 56

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 224)

            context[BenchmarkTestAtom1()] = 57

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 228)

            context[BenchmarkTestAtom1()] = 58

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 232)

            context[BenchmarkTestAtom1()] = 59

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 236)

            context[BenchmarkTestAtom1()] = 60

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 240)

            context[BenchmarkTestAtom1()] = 61

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 244)

            context[BenchmarkTestAtom1()] = 62

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 248)

            context[BenchmarkTestAtom1()] = 63

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 252)

            context[BenchmarkTestAtom1()] = 64

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 256)

            context[BenchmarkTestAtom1()] = 65

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 260)

            context[BenchmarkTestAtom1()] = 66

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 264)

            context[BenchmarkTestAtom1()] = 67

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 268)

            context[BenchmarkTestAtom1()] = 68

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 272)

            context[BenchmarkTestAtom1()] = 69

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 276)

            context[BenchmarkTestAtom1()] = 70

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 280)

            context[BenchmarkTestAtom1()] = 71

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 284)

            context[BenchmarkTestAtom1()] = 72

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 288)

            context[BenchmarkTestAtom1()] = 73

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 292)

            context[BenchmarkTestAtom1()] = 74

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 296)

            context[BenchmarkTestAtom1()] = 75

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 300)

            context[BenchmarkTestAtom1()] = 76

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 304)

            context[BenchmarkTestAtom1()] = 77

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 308)

            context[BenchmarkTestAtom1()] = 78

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 312)

            context[BenchmarkTestAtom1()] = 79

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 316)

            context[BenchmarkTestAtom1()] = 80

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 320)

            context[BenchmarkTestAtom1()] = 81

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 324)

            context[BenchmarkTestAtom1()] = 82

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 328)

            context[BenchmarkTestAtom1()] = 83

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 332)

            context[BenchmarkTestAtom1()] = 84

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 336)

            context[BenchmarkTestAtom1()] = 85

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 340)

            context[BenchmarkTestAtom1()] = 86

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 344)

            context[BenchmarkTestAtom1()] = 87

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 348)

            context[BenchmarkTestAtom1()] = 88

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 352)

            context[BenchmarkTestAtom1()] = 89

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 356)

            context[BenchmarkTestAtom1()] = 90

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 360)

            context[BenchmarkTestAtom1()] = 91

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 364)

            context[BenchmarkTestAtom1()] = 92

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 368)

            context[BenchmarkTestAtom1()] = 93

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 372)

            context[BenchmarkTestAtom1()] = 94

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 376)

            context[BenchmarkTestAtom1()] = 95

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 380)

            context[BenchmarkTestAtom1()] = 96

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 384)

            context[BenchmarkTestAtom1()] = 97

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 388)

            context[BenchmarkTestAtom1()] = 98

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 392)

            context[BenchmarkTestAtom1()] = 99

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 396)

            context[BenchmarkTestAtom1()] = 100

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 400)

            context[BenchmarkTestAtom1()] = 101

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 404)

            context[BenchmarkTestAtom1()] = 102

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 408)

            context[BenchmarkTestAtom1()] = 103

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 412)

            context[BenchmarkTestAtom1()] = 104

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 416)

            context[BenchmarkTestAtom1()] = 105

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 420)

            context[BenchmarkTestAtom1()] = 106

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 424)

            context[BenchmarkTestAtom1()] = 107

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 428)

            context[BenchmarkTestAtom1()] = 108

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 432)

            context[BenchmarkTestAtom1()] = 109

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 436)

            context[BenchmarkTestAtom1()] = 110

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 440)

            context[BenchmarkTestAtom1()] = 111

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 444)

            context[BenchmarkTestAtom1()] = 112

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 448)

            context[BenchmarkTestAtom1()] = 113

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 452)

            context[BenchmarkTestAtom1()] = 114

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 456)

            context[BenchmarkTestAtom1()] = 115

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 460)

            context[BenchmarkTestAtom1()] = 116

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 464)

            context[BenchmarkTestAtom1()] = 117

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 468)

            context[BenchmarkTestAtom1()] = 118

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 472)

            context[BenchmarkTestAtom1()] = 119

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 476)

            context[BenchmarkTestAtom1()] = 120

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 480)

            context[BenchmarkTestAtom1()] = 121

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 484)

            context[BenchmarkTestAtom1()] = 122

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 488)

            context[BenchmarkTestAtom1()] = 123

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 492)

            context[BenchmarkTestAtom1()] = 124

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 496)

            context[BenchmarkTestAtom1()] = 125

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 500)

            context[BenchmarkTestAtom1()] = 126

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 504)

            context[BenchmarkTestAtom1()] = 127

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 508)

            context[BenchmarkTestAtom1()] = 128

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 512)

            context[BenchmarkTestAtom1()] = 129

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 516)

            context[BenchmarkTestAtom1()] = 130

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 520)

            context[BenchmarkTestAtom1()] = 131

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 524)

            context[BenchmarkTestAtom1()] = 132

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 528)

            context[BenchmarkTestAtom1()] = 133

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 532)

            context[BenchmarkTestAtom1()] = 134

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 536)

            context[BenchmarkTestAtom1()] = 135

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 540)

            context[BenchmarkTestAtom1()] = 136

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 544)

            context[BenchmarkTestAtom1()] = 137

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 548)

            context[BenchmarkTestAtom1()] = 138

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 552)

            context[BenchmarkTestAtom1()] = 139

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 556)

            context[BenchmarkTestAtom1()] = 140

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 560)

            context[BenchmarkTestAtom1()] = 141

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 564)

            context[BenchmarkTestAtom1()] = 142

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 568)

            context[BenchmarkTestAtom1()] = 143

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 572)

            context[BenchmarkTestAtom1()] = 144

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 576)

            context[BenchmarkTestAtom1()] = 145

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 580)

            context[BenchmarkTestAtom1()] = 146

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 584)

            context[BenchmarkTestAtom1()] = 147

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 588)

            context[BenchmarkTestAtom1()] = 148

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 592)

            context[BenchmarkTestAtom1()] = 149

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 596)

            context[BenchmarkTestAtom1()] = 150

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 600)

            context[BenchmarkTestAtom1()] = 151

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 604)

            context[BenchmarkTestAtom1()] = 152

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 608)

            context[BenchmarkTestAtom1()] = 153

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 612)

            context[BenchmarkTestAtom1()] = 154

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 616)

            context[BenchmarkTestAtom1()] = 155

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 620)

            context[BenchmarkTestAtom1()] = 156

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 624)

            context[BenchmarkTestAtom1()] = 157

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 628)

            context[BenchmarkTestAtom1()] = 158

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 632)

            context[BenchmarkTestAtom1()] = 159

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 636)

            context[BenchmarkTestAtom1()] = 160

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 640)

            context[BenchmarkTestAtom1()] = 161

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 644)

            context[BenchmarkTestAtom1()] = 162

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 648)

            context[BenchmarkTestAtom1()] = 163

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 652)

            context[BenchmarkTestAtom1()] = 164

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 656)

            context[BenchmarkTestAtom1()] = 165

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 660)

            context[BenchmarkTestAtom1()] = 166

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 664)

            context[BenchmarkTestAtom1()] = 167

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 668)

            context[BenchmarkTestAtom1()] = 168

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 672)

            context[BenchmarkTestAtom1()] = 169

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 676)

            context[BenchmarkTestAtom1()] = 170

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 680)

            context[BenchmarkTestAtom1()] = 171

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 684)

            context[BenchmarkTestAtom1()] = 172

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 688)

            context[BenchmarkTestAtom1()] = 173

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 692)

            context[BenchmarkTestAtom1()] = 174

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 696)

            context[BenchmarkTestAtom1()] = 175

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 700)

            context[BenchmarkTestAtom1()] = 176

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 704)

            context[BenchmarkTestAtom1()] = 177

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 708)

            context[BenchmarkTestAtom1()] = 178

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 712)

            context[BenchmarkTestAtom1()] = 179

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 716)

            context[BenchmarkTestAtom1()] = 180

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 720)

            context[BenchmarkTestAtom1()] = 181

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 724)

            context[BenchmarkTestAtom1()] = 182

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 728)

            context[BenchmarkTestAtom1()] = 183

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 732)

            context[BenchmarkTestAtom1()] = 184

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 736)

            context[BenchmarkTestAtom1()] = 185

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 740)

            context[BenchmarkTestAtom1()] = 186

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 744)

            context[BenchmarkTestAtom1()] = 187

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 748)

            context[BenchmarkTestAtom1()] = 188

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 752)

            context[BenchmarkTestAtom1()] = 189

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 756)

            context[BenchmarkTestAtom1()] = 190

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 760)

            context[BenchmarkTestAtom1()] = 191

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 764)

            context[BenchmarkTestAtom1()] = 192

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 768)

            context[BenchmarkTestAtom1()] = 193

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 772)

            context[BenchmarkTestAtom1()] = 194

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 776)

            context[BenchmarkTestAtom1()] = 195

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 780)

            context[BenchmarkTestAtom1()] = 196

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 784)

            context[BenchmarkTestAtom1()] = 197

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 788)

            context[BenchmarkTestAtom1()] = 198

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 792)

            context[BenchmarkTestAtom1()] = 199

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 796)

            context[BenchmarkTestAtom1()] = 200

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 800)

            context[BenchmarkTestAtom1()] = 201

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 804)

            context[BenchmarkTestAtom1()] = 202

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 808)

            context[BenchmarkTestAtom1()] = 203

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 812)

            context[BenchmarkTestAtom1()] = 204

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 816)

            context[BenchmarkTestAtom1()] = 205

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 820)

            context[BenchmarkTestAtom1()] = 206

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 824)

            context[BenchmarkTestAtom1()] = 207

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 828)

            context[BenchmarkTestAtom1()] = 208

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 832)

            context[BenchmarkTestAtom1()] = 209

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 836)

            context[BenchmarkTestAtom1()] = 210

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 840)

            context[BenchmarkTestAtom1()] = 211

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 844)

            context[BenchmarkTestAtom1()] = 212

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 848)

            context[BenchmarkTestAtom1()] = 213

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 852)

            context[BenchmarkTestAtom1()] = 214

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 856)

            context[BenchmarkTestAtom1()] = 215

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 860)

            context[BenchmarkTestAtom1()] = 216

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 864)

            context[BenchmarkTestAtom1()] = 217

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 868)

            context[BenchmarkTestAtom1()] = 218

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 872)

            context[BenchmarkTestAtom1()] = 219

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 876)

            context[BenchmarkTestAtom1()] = 220

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 880)

            context[BenchmarkTestAtom1()] = 221

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 884)

            context[BenchmarkTestAtom1()] = 222

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 888)

            context[BenchmarkTestAtom1()] = 223

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 892)

            context[BenchmarkTestAtom1()] = 224

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 896)

            context[BenchmarkTestAtom1()] = 225

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 900)

            context[BenchmarkTestAtom1()] = 226

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 904)

            context[BenchmarkTestAtom1()] = 227

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 908)

            context[BenchmarkTestAtom1()] = 228

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 912)

            context[BenchmarkTestAtom1()] = 229

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 916)

            context[BenchmarkTestAtom1()] = 230

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 920)

            context[BenchmarkTestAtom1()] = 231

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 924)

            context[BenchmarkTestAtom1()] = 232

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 928)

            context[BenchmarkTestAtom1()] = 233

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 932)

            context[BenchmarkTestAtom1()] = 234

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 936)

            context[BenchmarkTestAtom1()] = 235

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 940)

            context[BenchmarkTestAtom1()] = 236

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 944)

            context[BenchmarkTestAtom1()] = 237

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 948)

            context[BenchmarkTestAtom1()] = 238

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 952)

            context[BenchmarkTestAtom1()] = 239

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 956)

            context[BenchmarkTestAtom1()] = 240

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 960)

            context[BenchmarkTestAtom1()] = 241

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 964)

            context[BenchmarkTestAtom1()] = 242

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 968)

            context[BenchmarkTestAtom1()] = 243

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 972)

            context[BenchmarkTestAtom1()] = 244

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 976)

            context[BenchmarkTestAtom1()] = 245

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 980)

            context[BenchmarkTestAtom1()] = 246

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 984)

            context[BenchmarkTestAtom1()] = 247

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 988)

            context[BenchmarkTestAtom1()] = 248

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 992)

            context[BenchmarkTestAtom1()] = 249

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 996)

            context[BenchmarkTestAtom1()] = 250

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1000)

            context[BenchmarkTestAtom1()] = 251

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1004)

            context[BenchmarkTestAtom1()] = 252

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1008)

            context[BenchmarkTestAtom1()] = 253

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1012)

            context[BenchmarkTestAtom1()] = 254

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1016)

            context[BenchmarkTestAtom1()] = 255

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1020)

            context[BenchmarkTestAtom1()] = 256

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1024)

            context[BenchmarkTestAtom1()] = 257

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1028)

            context[BenchmarkTestAtom1()] = 258

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1032)

            context[BenchmarkTestAtom1()] = 259

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1036)

            context[BenchmarkTestAtom1()] = 260

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1040)

            context[BenchmarkTestAtom1()] = 261

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1044)

            context[BenchmarkTestAtom1()] = 262

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1048)

            context[BenchmarkTestAtom1()] = 263

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1052)

            context[BenchmarkTestAtom1()] = 264

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1056)

            context[BenchmarkTestAtom1()] = 265

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1060)

            context[BenchmarkTestAtom1()] = 266

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1064)

            context[BenchmarkTestAtom1()] = 267

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1068)

            context[BenchmarkTestAtom1()] = 268

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1072)

            context[BenchmarkTestAtom1()] = 269

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1076)

            context[BenchmarkTestAtom1()] = 270

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1080)

            context[BenchmarkTestAtom1()] = 271

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1084)

            context[BenchmarkTestAtom1()] = 272

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1088)

            context[BenchmarkTestAtom1()] = 273

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1092)

            context[BenchmarkTestAtom1()] = 274

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1096)

            context[BenchmarkTestAtom1()] = 275

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1100)

            context[BenchmarkTestAtom1()] = 276

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1104)

            context[BenchmarkTestAtom1()] = 277

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1108)

            context[BenchmarkTestAtom1()] = 278

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1112)

            context[BenchmarkTestAtom1()] = 279

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1116)

            context[BenchmarkTestAtom1()] = 280

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1120)

            context[BenchmarkTestAtom1()] = 281

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1124)

            context[BenchmarkTestAtom1()] = 282

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1128)

            context[BenchmarkTestAtom1()] = 283

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1132)

            context[BenchmarkTestAtom1()] = 284

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1136)

            context[BenchmarkTestAtom1()] = 285

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1140)

            context[BenchmarkTestAtom1()] = 286

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1144)

            context[BenchmarkTestAtom1()] = 287

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1148)

            context[BenchmarkTestAtom1()] = 288

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1152)

            context[BenchmarkTestAtom1()] = 289

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1156)

            context[BenchmarkTestAtom1()] = 290

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1160)

            context[BenchmarkTestAtom1()] = 291

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1164)

            context[BenchmarkTestAtom1()] = 292

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1168)

            context[BenchmarkTestAtom1()] = 293

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1172)

            context[BenchmarkTestAtom1()] = 294

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1176)

            context[BenchmarkTestAtom1()] = 295

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1180)

            context[BenchmarkTestAtom1()] = 296

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1184)

            context[BenchmarkTestAtom1()] = 297

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1188)

            context[BenchmarkTestAtom1()] = 298

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1192)

            context[BenchmarkTestAtom1()] = 299

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1196)

            context[BenchmarkTestAtom1()] = 300

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1200)

            context[BenchmarkTestAtom1()] = 301

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1204)

            context[BenchmarkTestAtom1()] = 302

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1208)

            context[BenchmarkTestAtom1()] = 303

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1212)

            context[BenchmarkTestAtom1()] = 304

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1216)

            context[BenchmarkTestAtom1()] = 305

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1220)

            context[BenchmarkTestAtom1()] = 306

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1224)

            context[BenchmarkTestAtom1()] = 307

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1228)

            context[BenchmarkTestAtom1()] = 308

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1232)

            context[BenchmarkTestAtom1()] = 309

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1236)

            context[BenchmarkTestAtom1()] = 310

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1240)

            context[BenchmarkTestAtom1()] = 311

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1244)

            context[BenchmarkTestAtom1()] = 312

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1248)

            context[BenchmarkTestAtom1()] = 313

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1252)

            context[BenchmarkTestAtom1()] = 314

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1256)

            context[BenchmarkTestAtom1()] = 315

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1260)

            context[BenchmarkTestAtom1()] = 316

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1264)

            context[BenchmarkTestAtom1()] = 317

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1268)

            context[BenchmarkTestAtom1()] = 318

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1272)

            context[BenchmarkTestAtom1()] = 319

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1276)

            context[BenchmarkTestAtom1()] = 320

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1280)

            context[BenchmarkTestAtom1()] = 321

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1284)

            context[BenchmarkTestAtom1()] = 322

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1288)

            context[BenchmarkTestAtom1()] = 323

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1292)

            context[BenchmarkTestAtom1()] = 324

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1296)

            context[BenchmarkTestAtom1()] = 325

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1300)

            context[BenchmarkTestAtom1()] = 326

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1304)

            context[BenchmarkTestAtom1()] = 327

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1308)

            context[BenchmarkTestAtom1()] = 328

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1312)

            context[BenchmarkTestAtom1()] = 329

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1316)

            context[BenchmarkTestAtom1()] = 330

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1320)

            context[BenchmarkTestAtom1()] = 331

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1324)

            context[BenchmarkTestAtom1()] = 332

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1328)

            context[BenchmarkTestAtom1()] = 333

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1332)

            context[BenchmarkTestAtom1()] = 334

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1336)

            context[BenchmarkTestAtom1()] = 335

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1340)

            context[BenchmarkTestAtom1()] = 336

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1344)

            context[BenchmarkTestAtom1()] = 337

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1348)

            context[BenchmarkTestAtom1()] = 338

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1352)

            context[BenchmarkTestAtom1()] = 339

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1356)

            context[BenchmarkTestAtom1()] = 340

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1360)

            context[BenchmarkTestAtom1()] = 341

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1364)

            context[BenchmarkTestAtom1()] = 342

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1368)

            context[BenchmarkTestAtom1()] = 343

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1372)

            context[BenchmarkTestAtom1()] = 344

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1376)

            context[BenchmarkTestAtom1()] = 345

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1380)

            context[BenchmarkTestAtom1()] = 346

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1384)

            context[BenchmarkTestAtom1()] = 347

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1388)

            context[BenchmarkTestAtom1()] = 348

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1392)

            context[BenchmarkTestAtom1()] = 349

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1396)

            context[BenchmarkTestAtom1()] = 350

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1400)

            context[BenchmarkTestAtom1()] = 351

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1404)

            context[BenchmarkTestAtom1()] = 352

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1408)

            context[BenchmarkTestAtom1()] = 353

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1412)

            context[BenchmarkTestAtom1()] = 354

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1416)

            context[BenchmarkTestAtom1()] = 355

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1420)

            context[BenchmarkTestAtom1()] = 356

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1424)

            context[BenchmarkTestAtom1()] = 357

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1428)

            context[BenchmarkTestAtom1()] = 358

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1432)

            context[BenchmarkTestAtom1()] = 359

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1436)

            context[BenchmarkTestAtom1()] = 360

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1440)

            context[BenchmarkTestAtom1()] = 361

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1444)

            context[BenchmarkTestAtom1()] = 362

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1448)

            context[BenchmarkTestAtom1()] = 363

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1452)

            context[BenchmarkTestAtom1()] = 364

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1456)

            context[BenchmarkTestAtom1()] = 365

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1460)

            context[BenchmarkTestAtom1()] = 366

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1464)

            context[BenchmarkTestAtom1()] = 367

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1468)

            context[BenchmarkTestAtom1()] = 368

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1472)

            context[BenchmarkTestAtom1()] = 369

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1476)

            context[BenchmarkTestAtom1()] = 370

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1480)

            context[BenchmarkTestAtom1()] = 371

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1484)

            context[BenchmarkTestAtom1()] = 372

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1488)

            context[BenchmarkTestAtom1()] = 373

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1492)

            context[BenchmarkTestAtom1()] = 374

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1496)

            context[BenchmarkTestAtom1()] = 375

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1500)

            context[BenchmarkTestAtom1()] = 376

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1504)

            context[BenchmarkTestAtom1()] = 377

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1508)

            context[BenchmarkTestAtom1()] = 378

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1512)

            context[BenchmarkTestAtom1()] = 379

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1516)

            context[BenchmarkTestAtom1()] = 380

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1520)

            context[BenchmarkTestAtom1()] = 381

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1524)

            context[BenchmarkTestAtom1()] = 382

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1528)

            context[BenchmarkTestAtom1()] = 383

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1532)

            context[BenchmarkTestAtom1()] = 384

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1536)

            context[BenchmarkTestAtom1()] = 385

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1540)

            context[BenchmarkTestAtom1()] = 386

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1544)

            context[BenchmarkTestAtom1()] = 387

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1548)

            context[BenchmarkTestAtom1()] = 388

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1552)

            context[BenchmarkTestAtom1()] = 389

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1556)

            context[BenchmarkTestAtom1()] = 390

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1560)

            context[BenchmarkTestAtom1()] = 391

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1564)

            context[BenchmarkTestAtom1()] = 392

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1568)

            context[BenchmarkTestAtom1()] = 393

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1572)

            context[BenchmarkTestAtom1()] = 394

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1576)

            context[BenchmarkTestAtom1()] = 395

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1580)

            context[BenchmarkTestAtom1()] = 396

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1584)

            context[BenchmarkTestAtom1()] = 397

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1588)

            context[BenchmarkTestAtom1()] = 398

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1592)

            context[BenchmarkTestAtom1()] = 399

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1596)

            context[BenchmarkTestAtom1()] = 400

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1600)

            context[BenchmarkTestAtom1()] = 401

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1604)

            context[BenchmarkTestAtom1()] = 402

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1608)

            context[BenchmarkTestAtom1()] = 403

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1612)

            context[BenchmarkTestAtom1()] = 404

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1616)

            context[BenchmarkTestAtom1()] = 405

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1620)

            context[BenchmarkTestAtom1()] = 406

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1624)

            context[BenchmarkTestAtom1()] = 407

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1628)

            context[BenchmarkTestAtom1()] = 408

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1632)

            context[BenchmarkTestAtom1()] = 409

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1636)

            context[BenchmarkTestAtom1()] = 410

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1640)

            context[BenchmarkTestAtom1()] = 411

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1644)

            context[BenchmarkTestAtom1()] = 412

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1648)

            context[BenchmarkTestAtom1()] = 413

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1652)

            context[BenchmarkTestAtom1()] = 414

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1656)

            context[BenchmarkTestAtom1()] = 415

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1660)

            context[BenchmarkTestAtom1()] = 416

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1664)

            context[BenchmarkTestAtom1()] = 417

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1668)

            context[BenchmarkTestAtom1()] = 418

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1672)

            context[BenchmarkTestAtom1()] = 419

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1676)

            context[BenchmarkTestAtom1()] = 420

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1680)

            context[BenchmarkTestAtom1()] = 421

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1684)

            context[BenchmarkTestAtom1()] = 422

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1688)

            context[BenchmarkTestAtom1()] = 423

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1692)

            context[BenchmarkTestAtom1()] = 424

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1696)

            context[BenchmarkTestAtom1()] = 425

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1700)

            context[BenchmarkTestAtom1()] = 426

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1704)

            context[BenchmarkTestAtom1()] = 427

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1708)

            context[BenchmarkTestAtom1()] = 428

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1712)

            context[BenchmarkTestAtom1()] = 429

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1716)

            context[BenchmarkTestAtom1()] = 430

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1720)

            context[BenchmarkTestAtom1()] = 431

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1724)

            context[BenchmarkTestAtom1()] = 432

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1728)

            context[BenchmarkTestAtom1()] = 433

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1732)

            context[BenchmarkTestAtom1()] = 434

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1736)

            context[BenchmarkTestAtom1()] = 435

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1740)

            context[BenchmarkTestAtom1()] = 436

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1744)

            context[BenchmarkTestAtom1()] = 437

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1748)

            context[BenchmarkTestAtom1()] = 438

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1752)

            context[BenchmarkTestAtom1()] = 439

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1756)

            context[BenchmarkTestAtom1()] = 440

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1760)

            context[BenchmarkTestAtom1()] = 441

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1764)

            context[BenchmarkTestAtom1()] = 442

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1768)

            context[BenchmarkTestAtom1()] = 443

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1772)

            context[BenchmarkTestAtom1()] = 444

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1776)

            context[BenchmarkTestAtom1()] = 445

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1780)

            context[BenchmarkTestAtom1()] = 446

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1784)

            context[BenchmarkTestAtom1()] = 447

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1788)

            context[BenchmarkTestAtom1()] = 448

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1792)

            context[BenchmarkTestAtom1()] = 449

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1796)

            context[BenchmarkTestAtom1()] = 450

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1800)

            context[BenchmarkTestAtom1()] = 451

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1804)

            context[BenchmarkTestAtom1()] = 452

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1808)

            context[BenchmarkTestAtom1()] = 453

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1812)

            context[BenchmarkTestAtom1()] = 454

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1816)

            context[BenchmarkTestAtom1()] = 455

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1820)

            context[BenchmarkTestAtom1()] = 456

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1824)

            context[BenchmarkTestAtom1()] = 457

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1828)

            context[BenchmarkTestAtom1()] = 458

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1832)

            context[BenchmarkTestAtom1()] = 459

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1836)

            context[BenchmarkTestAtom1()] = 460

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1840)

            context[BenchmarkTestAtom1()] = 461

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1844)

            context[BenchmarkTestAtom1()] = 462

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1848)

            context[BenchmarkTestAtom1()] = 463

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1852)

            context[BenchmarkTestAtom1()] = 464

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1856)

            context[BenchmarkTestAtom1()] = 465

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1860)

            context[BenchmarkTestAtom1()] = 466

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1864)

            context[BenchmarkTestAtom1()] = 467

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1868)

            context[BenchmarkTestAtom1()] = 468

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1872)

            context[BenchmarkTestAtom1()] = 469

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1876)

            context[BenchmarkTestAtom1()] = 470

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1880)

            context[BenchmarkTestAtom1()] = 471

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1884)

            context[BenchmarkTestAtom1()] = 472

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1888)

            context[BenchmarkTestAtom1()] = 473

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1892)

            context[BenchmarkTestAtom1()] = 474

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1896)

            context[BenchmarkTestAtom1()] = 475

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1900)

            context[BenchmarkTestAtom1()] = 476

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1904)

            context[BenchmarkTestAtom1()] = 477

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1908)

            context[BenchmarkTestAtom1()] = 478

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1912)

            context[BenchmarkTestAtom1()] = 479

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1916)

            context[BenchmarkTestAtom1()] = 480

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1920)

            context[BenchmarkTestAtom1()] = 481

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1924)

            context[BenchmarkTestAtom1()] = 482

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1928)

            context[BenchmarkTestAtom1()] = 483

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1932)

            context[BenchmarkTestAtom1()] = 484

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1936)

            context[BenchmarkTestAtom1()] = 485

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1940)

            context[BenchmarkTestAtom1()] = 486

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1944)

            context[BenchmarkTestAtom1()] = 487

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1948)

            context[BenchmarkTestAtom1()] = 488

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1952)

            context[BenchmarkTestAtom1()] = 489

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1956)

            context[BenchmarkTestAtom1()] = 490

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1960)

            context[BenchmarkTestAtom1()] = 491

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1964)

            context[BenchmarkTestAtom1()] = 492

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1968)

            context[BenchmarkTestAtom1()] = 493

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1972)

            context[BenchmarkTestAtom1()] = 494

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1976)

            context[BenchmarkTestAtom1()] = 495

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1980)

            context[BenchmarkTestAtom1()] = 496

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1984)

            context[BenchmarkTestAtom1()] = 497

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1988)

            context[BenchmarkTestAtom1()] = 498

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1992)

            context[BenchmarkTestAtom1()] = 499

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 1996)

            context[BenchmarkTestAtom1()] = 500

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2000)

            context[BenchmarkTestAtom1()] = 501

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2004)

            context[BenchmarkTestAtom1()] = 502

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2008)

            context[BenchmarkTestAtom1()] = 503

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2012)

            context[BenchmarkTestAtom1()] = 504

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2016)

            context[BenchmarkTestAtom1()] = 505

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2020)

            context[BenchmarkTestAtom1()] = 506

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2024)

            context[BenchmarkTestAtom1()] = 507

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2028)

            context[BenchmarkTestAtom1()] = 508

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2032)

            context[BenchmarkTestAtom1()] = 509

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2036)

            context[BenchmarkTestAtom1()] = 510

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2040)

            context[BenchmarkTestAtom1()] = 511

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2044)

            context[BenchmarkTestAtom1()] = 512

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2048)

            context[BenchmarkTestAtom1()] = 513

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2052)

            context[BenchmarkTestAtom1()] = 514

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2056)

            context[BenchmarkTestAtom1()] = 515

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2060)

            context[BenchmarkTestAtom1()] = 516

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2064)

            context[BenchmarkTestAtom1()] = 517

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2068)

            context[BenchmarkTestAtom1()] = 518

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2072)

            context[BenchmarkTestAtom1()] = 519

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2076)

            context[BenchmarkTestAtom1()] = 520

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2080)

            context[BenchmarkTestAtom1()] = 521

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2084)

            context[BenchmarkTestAtom1()] = 522

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2088)

            context[BenchmarkTestAtom1()] = 523

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2092)

            context[BenchmarkTestAtom1()] = 524

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2096)

            context[BenchmarkTestAtom1()] = 525

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2100)

            context[BenchmarkTestAtom1()] = 526

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2104)

            context[BenchmarkTestAtom1()] = 527

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2108)

            context[BenchmarkTestAtom1()] = 528

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2112)

            context[BenchmarkTestAtom1()] = 529

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2116)

            context[BenchmarkTestAtom1()] = 530

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2120)

            context[BenchmarkTestAtom1()] = 531

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2124)

            context[BenchmarkTestAtom1()] = 532

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2128)

            context[BenchmarkTestAtom1()] = 533

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2132)

            context[BenchmarkTestAtom1()] = 534

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2136)

            context[BenchmarkTestAtom1()] = 535

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2140)

            context[BenchmarkTestAtom1()] = 536

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2144)

            context[BenchmarkTestAtom1()] = 537

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2148)

            context[BenchmarkTestAtom1()] = 538

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2152)

            context[BenchmarkTestAtom1()] = 539

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2156)

            context[BenchmarkTestAtom1()] = 540

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2160)

            context[BenchmarkTestAtom1()] = 541

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2164)

            context[BenchmarkTestAtom1()] = 542

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2168)

            context[BenchmarkTestAtom1()] = 543

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2172)

            context[BenchmarkTestAtom1()] = 544

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2176)

            context[BenchmarkTestAtom1()] = 545

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2180)

            context[BenchmarkTestAtom1()] = 546

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2184)

            context[BenchmarkTestAtom1()] = 547

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2188)

            context[BenchmarkTestAtom1()] = 548

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2192)

            context[BenchmarkTestAtom1()] = 549

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2196)

            context[BenchmarkTestAtom1()] = 550

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2200)

            context[BenchmarkTestAtom1()] = 551

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2204)

            context[BenchmarkTestAtom1()] = 552

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2208)

            context[BenchmarkTestAtom1()] = 553

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2212)

            context[BenchmarkTestAtom1()] = 554

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2216)

            context[BenchmarkTestAtom1()] = 555

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2220)

            context[BenchmarkTestAtom1()] = 556

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2224)

            context[BenchmarkTestAtom1()] = 557

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2228)

            context[BenchmarkTestAtom1()] = 558

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2232)

            context[BenchmarkTestAtom1()] = 559

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2236)

            context[BenchmarkTestAtom1()] = 560

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2240)

            context[BenchmarkTestAtom1()] = 561

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2244)

            context[BenchmarkTestAtom1()] = 562

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2248)

            context[BenchmarkTestAtom1()] = 563

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2252)

            context[BenchmarkTestAtom1()] = 564

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2256)

            context[BenchmarkTestAtom1()] = 565

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2260)

            context[BenchmarkTestAtom1()] = 566

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2264)

            context[BenchmarkTestAtom1()] = 567

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2268)

            context[BenchmarkTestAtom1()] = 568

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2272)

            context[BenchmarkTestAtom1()] = 569

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2276)

            context[BenchmarkTestAtom1()] = 570

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2280)

            context[BenchmarkTestAtom1()] = 571

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2284)

            context[BenchmarkTestAtom1()] = 572

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2288)

            context[BenchmarkTestAtom1()] = 573

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2292)

            context[BenchmarkTestAtom1()] = 574

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2296)

            context[BenchmarkTestAtom1()] = 575

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2300)

            context[BenchmarkTestAtom1()] = 576

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2304)

            context[BenchmarkTestAtom1()] = 577

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2308)

            context[BenchmarkTestAtom1()] = 578

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2312)

            context[BenchmarkTestAtom1()] = 579

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2316)

            context[BenchmarkTestAtom1()] = 580

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2320)

            context[BenchmarkTestAtom1()] = 581

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2324)

            context[BenchmarkTestAtom1()] = 582

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2328)

            context[BenchmarkTestAtom1()] = 583

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2332)

            context[BenchmarkTestAtom1()] = 584

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2336)

            context[BenchmarkTestAtom1()] = 585

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2340)

            context[BenchmarkTestAtom1()] = 586

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2344)

            context[BenchmarkTestAtom1()] = 587

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2348)

            context[BenchmarkTestAtom1()] = 588

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2352)

            context[BenchmarkTestAtom1()] = 589

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2356)

            context[BenchmarkTestAtom1()] = 590

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2360)

            context[BenchmarkTestAtom1()] = 591

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2364)

            context[BenchmarkTestAtom1()] = 592

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2368)

            context[BenchmarkTestAtom1()] = 593

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2372)

            context[BenchmarkTestAtom1()] = 594

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2376)

            context[BenchmarkTestAtom1()] = 595

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2380)

            context[BenchmarkTestAtom1()] = 596

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2384)

            context[BenchmarkTestAtom1()] = 597

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2388)

            context[BenchmarkTestAtom1()] = 598

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2392)

            context[BenchmarkTestAtom1()] = 599

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2396)

            context[BenchmarkTestAtom1()] = 600

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2400)

            context[BenchmarkTestAtom1()] = 601

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2404)

            context[BenchmarkTestAtom1()] = 602

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2408)

            context[BenchmarkTestAtom1()] = 603

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2412)

            context[BenchmarkTestAtom1()] = 604

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2416)

            context[BenchmarkTestAtom1()] = 605

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2420)

            context[BenchmarkTestAtom1()] = 606

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2424)

            context[BenchmarkTestAtom1()] = 607

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2428)

            context[BenchmarkTestAtom1()] = 608

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2432)

            context[BenchmarkTestAtom1()] = 609

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2436)

            context[BenchmarkTestAtom1()] = 610

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2440)

            context[BenchmarkTestAtom1()] = 611

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2444)

            context[BenchmarkTestAtom1()] = 612

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2448)

            context[BenchmarkTestAtom1()] = 613

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2452)

            context[BenchmarkTestAtom1()] = 614

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2456)

            context[BenchmarkTestAtom1()] = 615

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2460)

            context[BenchmarkTestAtom1()] = 616

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2464)

            context[BenchmarkTestAtom1()] = 617

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2468)

            context[BenchmarkTestAtom1()] = 618

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2472)

            context[BenchmarkTestAtom1()] = 619

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2476)

            context[BenchmarkTestAtom1()] = 620

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2480)

            context[BenchmarkTestAtom1()] = 621

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2484)

            context[BenchmarkTestAtom1()] = 622

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2488)

            context[BenchmarkTestAtom1()] = 623

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2492)

            context[BenchmarkTestAtom1()] = 624

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2496)

            context[BenchmarkTestAtom1()] = 625

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2500)

            context[BenchmarkTestAtom1()] = 626

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2504)

            context[BenchmarkTestAtom1()] = 627

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2508)

            context[BenchmarkTestAtom1()] = 628

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2512)

            context[BenchmarkTestAtom1()] = 629

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2516)

            context[BenchmarkTestAtom1()] = 630

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2520)

            context[BenchmarkTestAtom1()] = 631

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2524)

            context[BenchmarkTestAtom1()] = 632

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2528)

            context[BenchmarkTestAtom1()] = 633

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2532)

            context[BenchmarkTestAtom1()] = 634

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2536)

            context[BenchmarkTestAtom1()] = 635

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2540)

            context[BenchmarkTestAtom1()] = 636

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2544)

            context[BenchmarkTestAtom1()] = 637

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2548)

            context[BenchmarkTestAtom1()] = 638

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2552)

            context[BenchmarkTestAtom1()] = 639

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2556)

            context[BenchmarkTestAtom1()] = 640

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2560)

            context[BenchmarkTestAtom1()] = 641

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2564)

            context[BenchmarkTestAtom1()] = 642

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2568)

            context[BenchmarkTestAtom1()] = 643

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2572)

            context[BenchmarkTestAtom1()] = 644

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2576)

            context[BenchmarkTestAtom1()] = 645

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2580)

            context[BenchmarkTestAtom1()] = 646

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2584)

            context[BenchmarkTestAtom1()] = 647

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2588)

            context[BenchmarkTestAtom1()] = 648

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2592)

            context[BenchmarkTestAtom1()] = 649

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2596)

            context[BenchmarkTestAtom1()] = 650

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2600)

            context[BenchmarkTestAtom1()] = 651

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2604)

            context[BenchmarkTestAtom1()] = 652

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2608)

            context[BenchmarkTestAtom1()] = 653

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2612)

            context[BenchmarkTestAtom1()] = 654

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2616)

            context[BenchmarkTestAtom1()] = 655

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2620)

            context[BenchmarkTestAtom1()] = 656

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2624)

            context[BenchmarkTestAtom1()] = 657

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2628)

            context[BenchmarkTestAtom1()] = 658

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2632)

            context[BenchmarkTestAtom1()] = 659

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2636)

            context[BenchmarkTestAtom1()] = 660

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2640)

            context[BenchmarkTestAtom1()] = 661

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2644)

            context[BenchmarkTestAtom1()] = 662

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2648)

            context[BenchmarkTestAtom1()] = 663

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2652)

            context[BenchmarkTestAtom1()] = 664

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2656)

            context[BenchmarkTestAtom1()] = 665

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2660)

            context[BenchmarkTestAtom1()] = 666

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2664)

            context[BenchmarkTestAtom1()] = 667

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2668)

            context[BenchmarkTestAtom1()] = 668

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2672)

            context[BenchmarkTestAtom1()] = 669

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2676)

            context[BenchmarkTestAtom1()] = 670

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2680)

            context[BenchmarkTestAtom1()] = 671

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2684)

            context[BenchmarkTestAtom1()] = 672

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2688)

            context[BenchmarkTestAtom1()] = 673

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2692)

            context[BenchmarkTestAtom1()] = 674

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2696)

            context[BenchmarkTestAtom1()] = 675

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2700)

            context[BenchmarkTestAtom1()] = 676

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2704)

            context[BenchmarkTestAtom1()] = 677

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2708)

            context[BenchmarkTestAtom1()] = 678

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2712)

            context[BenchmarkTestAtom1()] = 679

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2716)

            context[BenchmarkTestAtom1()] = 680

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2720)

            context[BenchmarkTestAtom1()] = 681

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2724)

            context[BenchmarkTestAtom1()] = 682

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2728)

            context[BenchmarkTestAtom1()] = 683

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2732)

            context[BenchmarkTestAtom1()] = 684

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2736)

            context[BenchmarkTestAtom1()] = 685

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2740)

            context[BenchmarkTestAtom1()] = 686

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2744)

            context[BenchmarkTestAtom1()] = 687

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2748)

            context[BenchmarkTestAtom1()] = 688

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2752)

            context[BenchmarkTestAtom1()] = 689

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2756)

            context[BenchmarkTestAtom1()] = 690

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2760)

            context[BenchmarkTestAtom1()] = 691

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2764)

            context[BenchmarkTestAtom1()] = 692

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2768)

            context[BenchmarkTestAtom1()] = 693

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2772)

            context[BenchmarkTestAtom1()] = 694

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2776)

            context[BenchmarkTestAtom1()] = 695

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2780)

            context[BenchmarkTestAtom1()] = 696

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2784)

            context[BenchmarkTestAtom1()] = 697

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2788)

            context[BenchmarkTestAtom1()] = 698

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2792)

            context[BenchmarkTestAtom1()] = 699

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2796)

            context[BenchmarkTestAtom1()] = 700

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2800)

            context[BenchmarkTestAtom1()] = 701

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2804)

            context[BenchmarkTestAtom1()] = 702

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2808)

            context[BenchmarkTestAtom1()] = 703

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2812)

            context[BenchmarkTestAtom1()] = 704

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2816)

            context[BenchmarkTestAtom1()] = 705

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2820)

            context[BenchmarkTestAtom1()] = 706

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2824)

            context[BenchmarkTestAtom1()] = 707

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2828)

            context[BenchmarkTestAtom1()] = 708

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2832)

            context[BenchmarkTestAtom1()] = 709

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2836)

            context[BenchmarkTestAtom1()] = 710

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2840)

            context[BenchmarkTestAtom1()] = 711

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2844)

            context[BenchmarkTestAtom1()] = 712

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2848)

            context[BenchmarkTestAtom1()] = 713

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2852)

            context[BenchmarkTestAtom1()] = 714

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2856)

            context[BenchmarkTestAtom1()] = 715

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2860)

            context[BenchmarkTestAtom1()] = 716

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2864)

            context[BenchmarkTestAtom1()] = 717

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2868)

            context[BenchmarkTestAtom1()] = 718

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2872)

            context[BenchmarkTestAtom1()] = 719

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2876)

            context[BenchmarkTestAtom1()] = 720

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2880)

            context[BenchmarkTestAtom1()] = 721

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2884)

            context[BenchmarkTestAtom1()] = 722

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2888)

            context[BenchmarkTestAtom1()] = 723

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2892)

            context[BenchmarkTestAtom1()] = 724

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2896)

            context[BenchmarkTestAtom1()] = 725

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2900)

            context[BenchmarkTestAtom1()] = 726

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2904)

            context[BenchmarkTestAtom1()] = 727

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2908)

            context[BenchmarkTestAtom1()] = 728

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2912)

            context[BenchmarkTestAtom1()] = 729

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2916)

            context[BenchmarkTestAtom1()] = 730

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2920)

            context[BenchmarkTestAtom1()] = 731

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2924)

            context[BenchmarkTestAtom1()] = 732

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2928)

            context[BenchmarkTestAtom1()] = 733

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2932)

            context[BenchmarkTestAtom1()] = 734

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2936)

            context[BenchmarkTestAtom1()] = 735

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2940)

            context[BenchmarkTestAtom1()] = 736

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2944)

            context[BenchmarkTestAtom1()] = 737

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2948)

            context[BenchmarkTestAtom1()] = 738

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2952)

            context[BenchmarkTestAtom1()] = 739

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2956)

            context[BenchmarkTestAtom1()] = 740

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2960)

            context[BenchmarkTestAtom1()] = 741

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2964)

            context[BenchmarkTestAtom1()] = 742

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2968)

            context[BenchmarkTestAtom1()] = 743

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2972)

            context[BenchmarkTestAtom1()] = 744

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2976)

            context[BenchmarkTestAtom1()] = 745

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2980)

            context[BenchmarkTestAtom1()] = 746

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2984)

            context[BenchmarkTestAtom1()] = 747

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2988)

            context[BenchmarkTestAtom1()] = 748

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2992)

            context[BenchmarkTestAtom1()] = 749

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 2996)

            context[BenchmarkTestAtom1()] = 750

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3000)

            context[BenchmarkTestAtom1()] = 751

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3004)

            context[BenchmarkTestAtom1()] = 752

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3008)

            context[BenchmarkTestAtom1()] = 753

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3012)

            context[BenchmarkTestAtom1()] = 754

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3016)

            context[BenchmarkTestAtom1()] = 755

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3020)

            context[BenchmarkTestAtom1()] = 756

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3024)

            context[BenchmarkTestAtom1()] = 757

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3028)

            context[BenchmarkTestAtom1()] = 758

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3032)

            context[BenchmarkTestAtom1()] = 759

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3036)

            context[BenchmarkTestAtom1()] = 760

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3040)

            context[BenchmarkTestAtom1()] = 761

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3044)

            context[BenchmarkTestAtom1()] = 762

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3048)

            context[BenchmarkTestAtom1()] = 763

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3052)

            context[BenchmarkTestAtom1()] = 764

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3056)

            context[BenchmarkTestAtom1()] = 765

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3060)

            context[BenchmarkTestAtom1()] = 766

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3064)

            context[BenchmarkTestAtom1()] = 767

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3068)

            context[BenchmarkTestAtom1()] = 768

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3072)

            context[BenchmarkTestAtom1()] = 769

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3076)

            context[BenchmarkTestAtom1()] = 770

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3080)

            context[BenchmarkTestAtom1()] = 771

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3084)

            context[BenchmarkTestAtom1()] = 772

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3088)

            context[BenchmarkTestAtom1()] = 773

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3092)

            context[BenchmarkTestAtom1()] = 774

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3096)

            context[BenchmarkTestAtom1()] = 775

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3100)

            context[BenchmarkTestAtom1()] = 776

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3104)

            context[BenchmarkTestAtom1()] = 777

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3108)

            context[BenchmarkTestAtom1()] = 778

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3112)

            context[BenchmarkTestAtom1()] = 779

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3116)

            context[BenchmarkTestAtom1()] = 780

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3120)

            context[BenchmarkTestAtom1()] = 781

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3124)

            context[BenchmarkTestAtom1()] = 782

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3128)

            context[BenchmarkTestAtom1()] = 783

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3132)

            context[BenchmarkTestAtom1()] = 784

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3136)

            context[BenchmarkTestAtom1()] = 785

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3140)

            context[BenchmarkTestAtom1()] = 786

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3144)

            context[BenchmarkTestAtom1()] = 787

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3148)

            context[BenchmarkTestAtom1()] = 788

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3152)

            context[BenchmarkTestAtom1()] = 789

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3156)

            context[BenchmarkTestAtom1()] = 790

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3160)

            context[BenchmarkTestAtom1()] = 791

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3164)

            context[BenchmarkTestAtom1()] = 792

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3168)

            context[BenchmarkTestAtom1()] = 793

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3172)

            context[BenchmarkTestAtom1()] = 794

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3176)

            context[BenchmarkTestAtom1()] = 795

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3180)

            context[BenchmarkTestAtom1()] = 796

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3184)

            context[BenchmarkTestAtom1()] = 797

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3188)

            context[BenchmarkTestAtom1()] = 798

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3192)

            context[BenchmarkTestAtom1()] = 799

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3196)

            context[BenchmarkTestAtom1()] = 800

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3200)

            context[BenchmarkTestAtom1()] = 801

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3204)

            context[BenchmarkTestAtom1()] = 802

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3208)

            context[BenchmarkTestAtom1()] = 803

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3212)

            context[BenchmarkTestAtom1()] = 804

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3216)

            context[BenchmarkTestAtom1()] = 805

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3220)

            context[BenchmarkTestAtom1()] = 806

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3224)

            context[BenchmarkTestAtom1()] = 807

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3228)

            context[BenchmarkTestAtom1()] = 808

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3232)

            context[BenchmarkTestAtom1()] = 809

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3236)

            context[BenchmarkTestAtom1()] = 810

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3240)

            context[BenchmarkTestAtom1()] = 811

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3244)

            context[BenchmarkTestAtom1()] = 812

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3248)

            context[BenchmarkTestAtom1()] = 813

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3252)

            context[BenchmarkTestAtom1()] = 814

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3256)

            context[BenchmarkTestAtom1()] = 815

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3260)

            context[BenchmarkTestAtom1()] = 816

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3264)

            context[BenchmarkTestAtom1()] = 817

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3268)

            context[BenchmarkTestAtom1()] = 818

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3272)

            context[BenchmarkTestAtom1()] = 819

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3276)

            context[BenchmarkTestAtom1()] = 820

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3280)

            context[BenchmarkTestAtom1()] = 821

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3284)

            context[BenchmarkTestAtom1()] = 822

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3288)

            context[BenchmarkTestAtom1()] = 823

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3292)

            context[BenchmarkTestAtom1()] = 824

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3296)

            context[BenchmarkTestAtom1()] = 825

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3300)

            context[BenchmarkTestAtom1()] = 826

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3304)

            context[BenchmarkTestAtom1()] = 827

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3308)

            context[BenchmarkTestAtom1()] = 828

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3312)

            context[BenchmarkTestAtom1()] = 829

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3316)

            context[BenchmarkTestAtom1()] = 830

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3320)

            context[BenchmarkTestAtom1()] = 831

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3324)

            context[BenchmarkTestAtom1()] = 832

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3328)

            context[BenchmarkTestAtom1()] = 833

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3332)

            context[BenchmarkTestAtom1()] = 834

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3336)

            context[BenchmarkTestAtom1()] = 835

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3340)

            context[BenchmarkTestAtom1()] = 836

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3344)

            context[BenchmarkTestAtom1()] = 837

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3348)

            context[BenchmarkTestAtom1()] = 838

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3352)

            context[BenchmarkTestAtom1()] = 839

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3356)

            context[BenchmarkTestAtom1()] = 840

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3360)

            context[BenchmarkTestAtom1()] = 841

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3364)

            context[BenchmarkTestAtom1()] = 842

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3368)

            context[BenchmarkTestAtom1()] = 843

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3372)

            context[BenchmarkTestAtom1()] = 844

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3376)

            context[BenchmarkTestAtom1()] = 845

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3380)

            context[BenchmarkTestAtom1()] = 846

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3384)

            context[BenchmarkTestAtom1()] = 847

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3388)

            context[BenchmarkTestAtom1()] = 848

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3392)

            context[BenchmarkTestAtom1()] = 849

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3396)

            context[BenchmarkTestAtom1()] = 850

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3400)

            context[BenchmarkTestAtom1()] = 851

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3404)

            context[BenchmarkTestAtom1()] = 852

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3408)

            context[BenchmarkTestAtom1()] = 853

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3412)

            context[BenchmarkTestAtom1()] = 854

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3416)

            context[BenchmarkTestAtom1()] = 855

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3420)

            context[BenchmarkTestAtom1()] = 856

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3424)

            context[BenchmarkTestAtom1()] = 857

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3428)

            context[BenchmarkTestAtom1()] = 858

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3432)

            context[BenchmarkTestAtom1()] = 859

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3436)

            context[BenchmarkTestAtom1()] = 860

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3440)

            context[BenchmarkTestAtom1()] = 861

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3444)

            context[BenchmarkTestAtom1()] = 862

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3448)

            context[BenchmarkTestAtom1()] = 863

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3452)

            context[BenchmarkTestAtom1()] = 864

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3456)

            context[BenchmarkTestAtom1()] = 865

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3460)

            context[BenchmarkTestAtom1()] = 866

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3464)

            context[BenchmarkTestAtom1()] = 867

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3468)

            context[BenchmarkTestAtom1()] = 868

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3472)

            context[BenchmarkTestAtom1()] = 869

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3476)

            context[BenchmarkTestAtom1()] = 870

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3480)

            context[BenchmarkTestAtom1()] = 871

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3484)

            context[BenchmarkTestAtom1()] = 872

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3488)

            context[BenchmarkTestAtom1()] = 873

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3492)

            context[BenchmarkTestAtom1()] = 874

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3496)

            context[BenchmarkTestAtom1()] = 875

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3500)

            context[BenchmarkTestAtom1()] = 876

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3504)

            context[BenchmarkTestAtom1()] = 877

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3508)

            context[BenchmarkTestAtom1()] = 878

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3512)

            context[BenchmarkTestAtom1()] = 879

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3516)

            context[BenchmarkTestAtom1()] = 880

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3520)

            context[BenchmarkTestAtom1()] = 881

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3524)

            context[BenchmarkTestAtom1()] = 882

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3528)

            context[BenchmarkTestAtom1()] = 883

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3532)

            context[BenchmarkTestAtom1()] = 884

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3536)

            context[BenchmarkTestAtom1()] = 885

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3540)

            context[BenchmarkTestAtom1()] = 886

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3544)

            context[BenchmarkTestAtom1()] = 887

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3548)

            context[BenchmarkTestAtom1()] = 888

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3552)

            context[BenchmarkTestAtom1()] = 889

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3556)

            context[BenchmarkTestAtom1()] = 890

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3560)

            context[BenchmarkTestAtom1()] = 891

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3564)

            context[BenchmarkTestAtom1()] = 892

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3568)

            context[BenchmarkTestAtom1()] = 893

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3572)

            context[BenchmarkTestAtom1()] = 894

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3576)

            context[BenchmarkTestAtom1()] = 895

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3580)

            context[BenchmarkTestAtom1()] = 896

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3584)

            context[BenchmarkTestAtom1()] = 897

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3588)

            context[BenchmarkTestAtom1()] = 898

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3592)

            context[BenchmarkTestAtom1()] = 899

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3596)

            context[BenchmarkTestAtom1()] = 900

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3600)

            context[BenchmarkTestAtom1()] = 901

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3604)

            context[BenchmarkTestAtom1()] = 902

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3608)

            context[BenchmarkTestAtom1()] = 903

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3612)

            context[BenchmarkTestAtom1()] = 904

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3616)

            context[BenchmarkTestAtom1()] = 905

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3620)

            context[BenchmarkTestAtom1()] = 906

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3624)

            context[BenchmarkTestAtom1()] = 907

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3628)

            context[BenchmarkTestAtom1()] = 908

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3632)

            context[BenchmarkTestAtom1()] = 909

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3636)

            context[BenchmarkTestAtom1()] = 910

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3640)

            context[BenchmarkTestAtom1()] = 911

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3644)

            context[BenchmarkTestAtom1()] = 912

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3648)

            context[BenchmarkTestAtom1()] = 913

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3652)

            context[BenchmarkTestAtom1()] = 914

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3656)

            context[BenchmarkTestAtom1()] = 915

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3660)

            context[BenchmarkTestAtom1()] = 916

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3664)

            context[BenchmarkTestAtom1()] = 917

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3668)

            context[BenchmarkTestAtom1()] = 918

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3672)

            context[BenchmarkTestAtom1()] = 919

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3676)

            context[BenchmarkTestAtom1()] = 920

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3680)

            context[BenchmarkTestAtom1()] = 921

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3684)

            context[BenchmarkTestAtom1()] = 922

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3688)

            context[BenchmarkTestAtom1()] = 923

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3692)

            context[BenchmarkTestAtom1()] = 924

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3696)

            context[BenchmarkTestAtom1()] = 925

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3700)

            context[BenchmarkTestAtom1()] = 926

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3704)

            context[BenchmarkTestAtom1()] = 927

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3708)

            context[BenchmarkTestAtom1()] = 928

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3712)

            context[BenchmarkTestAtom1()] = 929

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3716)

            context[BenchmarkTestAtom1()] = 930

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3720)

            context[BenchmarkTestAtom1()] = 931

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3724)

            context[BenchmarkTestAtom1()] = 932

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3728)

            context[BenchmarkTestAtom1()] = 933

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3732)

            context[BenchmarkTestAtom1()] = 934

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3736)

            context[BenchmarkTestAtom1()] = 935

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3740)

            context[BenchmarkTestAtom1()] = 936

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3744)

            context[BenchmarkTestAtom1()] = 937

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3748)

            context[BenchmarkTestAtom1()] = 938

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3752)

            context[BenchmarkTestAtom1()] = 939

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3756)

            context[BenchmarkTestAtom1()] = 940

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3760)

            context[BenchmarkTestAtom1()] = 941

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3764)

            context[BenchmarkTestAtom1()] = 942

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3768)

            context[BenchmarkTestAtom1()] = 943

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3772)

            context[BenchmarkTestAtom1()] = 944

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3776)

            context[BenchmarkTestAtom1()] = 945

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3780)

            context[BenchmarkTestAtom1()] = 946

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3784)

            context[BenchmarkTestAtom1()] = 947

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3788)

            context[BenchmarkTestAtom1()] = 948

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3792)

            context[BenchmarkTestAtom1()] = 949

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3796)

            context[BenchmarkTestAtom1()] = 950

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3800)

            context[BenchmarkTestAtom1()] = 951

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3804)

            context[BenchmarkTestAtom1()] = 952

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3808)

            context[BenchmarkTestAtom1()] = 953

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3812)

            context[BenchmarkTestAtom1()] = 954

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3816)

            context[BenchmarkTestAtom1()] = 955

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3820)

            context[BenchmarkTestAtom1()] = 956

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3824)

            context[BenchmarkTestAtom1()] = 957

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3828)

            context[BenchmarkTestAtom1()] = 958

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3832)

            context[BenchmarkTestAtom1()] = 959

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3836)

            context[BenchmarkTestAtom1()] = 960

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3840)

            context[BenchmarkTestAtom1()] = 961

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3844)

            context[BenchmarkTestAtom1()] = 962

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3848)

            context[BenchmarkTestAtom1()] = 963

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3852)

            context[BenchmarkTestAtom1()] = 964

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3856)

            context[BenchmarkTestAtom1()] = 965

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3860)

            context[BenchmarkTestAtom1()] = 966

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3864)

            context[BenchmarkTestAtom1()] = 967

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3868)

            context[BenchmarkTestAtom1()] = 968

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3872)

            context[BenchmarkTestAtom1()] = 969

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3876)

            context[BenchmarkTestAtom1()] = 970

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3880)

            context[BenchmarkTestAtom1()] = 971

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3884)

            context[BenchmarkTestAtom1()] = 972

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3888)

            context[BenchmarkTestAtom1()] = 973

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3892)

            context[BenchmarkTestAtom1()] = 974

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3896)

            context[BenchmarkTestAtom1()] = 975

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3900)

            context[BenchmarkTestAtom1()] = 976

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3904)

            context[BenchmarkTestAtom1()] = 977

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3908)

            context[BenchmarkTestAtom1()] = 978

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3912)

            context[BenchmarkTestAtom1()] = 979

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3916)

            context[BenchmarkTestAtom1()] = 980

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3920)

            context[BenchmarkTestAtom1()] = 981

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3924)

            context[BenchmarkTestAtom1()] = 982

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3928)

            context[BenchmarkTestAtom1()] = 983

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3932)

            context[BenchmarkTestAtom1()] = 984

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3936)

            context[BenchmarkTestAtom1()] = 985

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3940)

            context[BenchmarkTestAtom1()] = 986

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3944)

            context[BenchmarkTestAtom1()] = 987

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3948)

            context[BenchmarkTestAtom1()] = 988

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3952)

            context[BenchmarkTestAtom1()] = 989

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3956)

            context[BenchmarkTestAtom1()] = 990

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3960)

            context[BenchmarkTestAtom1()] = 991

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3964)

            context[BenchmarkTestAtom1()] = 992

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3968)

            context[BenchmarkTestAtom1()] = 993

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3972)

            context[BenchmarkTestAtom1()] = 994

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3976)

            context[BenchmarkTestAtom1()] = 995

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3980)

            context[BenchmarkTestAtom1()] = 996

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3984)

            context[BenchmarkTestAtom1()] = 997

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3988)

            context[BenchmarkTestAtom1()] = 998

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3992)

            context[BenchmarkTestAtom1()] = 999

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 3996)

            context[BenchmarkTestAtom1()] = 1000

            XCTAssertEqual(context.watch(BenchmarkTestAtom()), 4000)
        }
    }
}
