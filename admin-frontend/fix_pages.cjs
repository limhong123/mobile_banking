const fs = require('fs');
const path = require('path');

function processDir(dir) {
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const fullPath = path.join(dir, file);
        if (fs.statSync(fullPath).isDirectory()) {
            processDir(fullPath);
        } else if (fullPath.endsWith('.jsx')) {
            let content = fs.readFileSync(fullPath, 'utf8');
            
            // Remove Sidebar import
            content = content.replace(/import\s+Sidebar\s+from\s+["'].*?Sidebar["'];?\s*/g, '');
            
            // Remove <Sidebar /> tag
            content = content.replace(/<Sidebar\s*\/>\s*/g, '');
            
            // Replace <div className="min-h-screen bg-slate-50"> ... <main ...> with just <>
            content = content.replace(/<div\s+className=["']min-h-screen\s+bg-slate-50["']>\s*<main\s+className=["'][^"']*["']>/g, '<>');
            
            // Or if they are separated
            content = content.replace(/<div\s+className=["']min-h-screen\s+bg-slate-50["']>\s*/g, '<>\n');
            content = content.replace(/<main\s+className=["']ml-\[255px\]\s+min-h-screen\s+p-8["']>\s*/g, '');
            
            // Replace closing </main></div> with </>
            content = content.replace(/<\/main>\s*<\/div>/g, '</>');
            
            fs.writeFileSync(fullPath, content);
        }
    }
}

processDir(path.join(__dirname, 'src/pages'));
