exports.handler = async () => {
    const synthetics = require('Synthetics');
    const page = await synthetics.getPage();

    const response = await page.goto("https://khalidhashim.com");

    if (!response || response.status() !== 200) {
        throw new Error("Website is down");
    }
};