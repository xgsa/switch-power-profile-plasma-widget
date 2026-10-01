import QtQuick

import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    // The widget is just a button without a popup, so show it directly
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.ConfigurableBackground


    property QtObject pmSource: Plasma5Support.DataSource {
        id: pmSource
        engine: "powermanagement"
        connectedSources: sources
        onSourceAdded: source => {
            disconnectSource(source);
            connectSource(source);
        }
        onSourceRemoved: source => {
            disconnectSource(source);
        }
    }

    readonly property var powerProfilesData: pmSource.data["Power Profiles"] || null
    readonly property string actuallyActiveProfile: powerProfilesData ? (powerProfilesData["Current Profile"] || "") : ""
    readonly property var supportedProfiles: powerProfilesData ? (powerProfilesData["Profiles"] || []) : []
    readonly property string iconsPath: Qt.resolvedUrl("../icons/")
    readonly property var modeNames: ({
        "power-saver": i18n("Power Save"),
        "balanced": i18n("Balanced"),
        "performance": i18n("Performance"),
    })

    // Error of the last switch attempt, shown in the tooltip until the profile changes
    property string lastError: ""

    onActuallyActiveProfileChanged: lastError = ""

    function toggleProfile() {
        if (actuallyActiveProfile === "") {
            lastError = i18n("Power profiles are not available (is power-profiles-daemon running?)");
            return;
        }
        const profile = actuallyActiveProfile === "performance" ? "power-saver" : "performance";
        if (!supportedProfiles.includes(profile)) {
            lastError = i18n("%1 mode is not supported on this system", modeNames[profile]);
            return;
        }

        const service = pmSource.serviceForSource("PowerDevil");
        const op = service.operationDescription("setPowerProfile");
        op.profile = profile;

        const job = service.startOperationCall(op);
        job.finished.connect(job => {
            if (!job.result) {
                console.warn("Failed to set power profile " + profile + ": " + job.errorString);
                lastError = i18n("Failed to activate %1 mode", modeNames[profile]);
                return;
            }
            lastError = "";
        });
    }

    fullRepresentation: MouseArea {
        activeFocusOnTab: true
        hoverEnabled: true

        Kirigami.Icon {
            anchors.fill: parent
            // Icons are monochrome, so recolor them to follow the panel's color scheme
            isMask: true
            color: Kirigami.Theme.textColor
            source: {
                const known_profile = ["power-saver", "performance", "balanced"].includes(actuallyActiveProfile)
                return iconsPath + (known_profile ? actuallyActiveProfile : "unknown-mode" ) + ".svg"
            }
            active: parent.containsMouse
        }
        onClicked: toggleProfile()
        Keys.onPressed: event => {
            if ([Qt.Key_Space, Qt.Key_Enter, Qt.Key_Return, Qt.Key_Select].includes(event.key)) {
                toggleProfile();
                event.accepted = true;
            }
        }
    }

    toolTipMainText: i18n("Active Power Profile")
    toolTipSubText: {
        const name = modeNames[actuallyActiveProfile] || i18n("Unknown")
        return lastError ? name + "\n" + lastError : name
    }
}
