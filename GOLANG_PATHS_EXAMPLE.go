package utilities

// USAGE

// main.go
// import (
// 	"myapp/utilities"
// )

// func main() {
// 	// init paths root
// 	utilities.InitPaths(utilities.ProjectRoot())
// 	// Perform setup operations
// 	print(utilities.Folders.DataPath)
// 	// utilities.Setup(utilities.Path(utilities.Extras.EnvFile))
// }

// //highly costumizable

// //as simple as that :)

import (
	"path/filepath"
	"runtime"
)

type OutFile string
type InFile string
type Folder string
type RootFile string //stays under root

var Folders = struct {
	Root      Folder
	DataPath  Folder
	WorkPath  Folder
	FinalPath Folder
}{
	Root:      "", // set by InitPaths
	DataPath:  "data",
	WorkPath:  "works",
	FinalPath: "final",
}

var FilesOUT = struct {
	StoryOUT          OutFile
	TTsOUT            OutFile
	SocialPostHTMLOUT OutFile
	SocialPostPNGOUT  OutFile
	SocialPostNLOUT   OutFile
	ClipOUT           OutFile
	SubtitlesOUT      OutFile
	AudioOUT          OutFile
	VideoOUT          OutFile
}{
	StoryOUT:          "Story.json",
	TTsOUT:            "Voice.mp3",
	SocialPostHTMLOUT: "Post.html",
	SocialPostPNGOUT:  "Post.png",
	SocialPostNLOUT:   "subs_guide.json",
	ClipOUT:           "Clip.mp4",
	SubtitlesOUT:      "Subs.json",
	AudioOUT:          "Audio.mp3",
	VideoOUT:          "Video.mp4",
}

var FilesIN = struct {
	ScriptIN InFile
	ConfigIN InFile
}{
	ScriptIN: "script.txt",
	ConfigIN: "config.json",
}

var Extras = struct {
	EnvFile       RootFile // will live under root
	MixedMediaOUT Folder   // treated as a folder name under Root
}{
	EnvFile:       ".env",
	MixedMediaOUT: "DONE",
}

// InitPaths sets the project root
func InitPaths(root string) {
	Folders.Root = Folder(root)
}

// ProjectRoot detects the project root (call once at startup)
func ProjectRoot() string {
	_, b, _, ok := runtime.Caller(0)
	if !ok {
		panic("Failed to determine project root")
	}
	return filepath.Dir(filepath.Dir(b))
}

// ---------- Smart Path switcher ----------

func Path(name any) string {
	root := string(Folders.Root)

	switch v := name.(type) {
	case OutFile:
		return filepath.Join(root, string(Folders.WorkPath), string(v))

	case InFile:
		return filepath.Join(root, string(Folders.DataPath), string(v))

	case Folder:
		// Folder → just Root + folder name
		return filepath.Join(root, string(v))

	case RootFile:
		// root file
		return filepath.Join(root, string(v))

	default:
		panic("Path: unsupported type")
	}
}
