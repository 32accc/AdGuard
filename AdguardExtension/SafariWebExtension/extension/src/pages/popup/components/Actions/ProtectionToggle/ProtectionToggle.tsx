/* eslint-disable */
import React, { useContext } from 'react';
import { observer } from 'mobx-react';

import { translator } from '../../../../common/translators/translator';
import { Action } from '../Action';
import { Switcher } from '../../Switcher';
import { popupStore } from '../../../stores/PopupStore';
import { Button } from '../../Button';
import { Icon } from '../../ui/Icon';

export const ProtectionToggle = observer(() => {
    const store = useContext(popupStore);

    const toggleProtection = () => {
        store.toggleProtection();
    };

    let description = translator.getMessage('popup_action_safari_protection_description');
    let descriptionColor = 'gray';
    let iconEnabled = true;

    let button;

    if (!store.contentBlockersEnabled) {
        description = translator.getMessage('popup_action_safari_protection_description_disabled');
        descriptionColor = 'yellow';
        iconEnabled = false;

        const handleInfoTouch = () => {
            store.setProtectionModalVisibleState(true);
        };

        button = (
            <Button onClick={handleInfoTouch} classNames="actions__control">
                <Icon color="yellow" iconId="info" />
            </Button>
        );
    } else {
        iconEnabled = store.protectionEnabled;

        button = <div className="actions__control">
            <Switcher onChange={toggleProtection} enabled={store.protectionEnabled} />
        </div>
    }

    return (
        <label className="action-label">
            <Action
                iconId="compass"
                iconColor="green"
                title={translator.getMessage('popup_action_safari_protection_title')}
                titleMod="light"
                description={description}
                descriptionMod={descriptionColor}
                iconEnabled={iconEnabled}
            >
                {button}
            </Action>
        </label>
    );
});