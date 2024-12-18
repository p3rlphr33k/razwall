/*
* +--------------------------------------------------------------------------+
* | Endian Firewall                                                          |
* +--------------------------------------------------------------------------+
* | Copyright (c) 2005-2015 Endian                                           |
* |         Endian GmbH/Srl                                                  |
* |         Bergweg 41 Via Monte                                             |
* |         39057 Eppan/Appiano                                              |
* |         ITALIEN/ITALIA                                                   |
* |         info@endian.com                                                  |
* |                                                                          |
* | emi is free software: you can redistribute it and/or modify              |
* | it under the terms of the GNU Lesser General Public License as published |
* | by the Free Software Foundation, either version 2.1 of the License, or   |
* | (at your option) any later version.                                      |
* |                                                                          |
* | emi is distributed in the hope that it will be useful,                   |
* | but WITHOUT ANY WARRANTY; without even the implied warranty of           |
* | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            |
* | GNU Lesser General Public License for more details.                      |
* |                                                                          |
* | You should have received a copy of the GNU Lesser General Public License |
* | along with emi.  If not, see <http://www.gnu.org/licenses/>.             |
* +--------------------------------------------------------------------------+
*/
OTP_SECRET_LENGTH = 10

otpQrCodes = {};

function generateSecret(id, name, issuer) {
    var result = '';
    for (var i = 0; i < OTP_SECRET_LENGTH; i++) {
        result += String.fromCharCode(Math.floor((Math.random() * 256)));
    }
    result = base32.encode(result).replace(/=/g, '');
    $('#' + id).val(result);
    drawQRCode(id, name);
    return result;
}

function drawQRCode(id, name, issuer) {
    if (name === undefined) {
        name = 'name';
    }
    if (issuer === undefined) {
        issuer = 'domain';
    }
    var value = $('#' + id).val();
    $('#' + id + '_button2').prop('disabled', !Boolean(value));

    var qrCode = otpQrCodes[id];
    if (qrCode === undefined) {
        qrCode = new QRCode(id + '_qrcode', {
            width: 256,
            height: 256,
            colorDark : '#000000',
            colorLight : '#ffffff'
        });
        otpQrCodes[id] = qrCode;
    }
    name = encodeURIComponent($('#'+name).val());
    issuer = encodeURIComponent($('#'+issuer).val());
    if (issuer) {
        name = issuer + ':' + name;
    }
    var url = 'otpauth://totp/' + name + '?secret=' + value;
    qrCode.makeCode(url);
};

function showQRCode(id) {
    $('#' + id + '_dialog').dialog({
       resizable: false,
       height: 330,
       width: 280,
       modal: true
    });
}
