let userAvatar = 'https://i.imgur.com/6MgCm6u.png';
let aiAvatar = 'https://i.imgur.com/YOJjZlW.png';
let aiName = 'AI助手';
let isTyping = false;
let avatarsLoaded = false;
let qqNumber = '';

function preloadImages(urls, callback) {
    let loadedImages = 0;
    const totalImages = urls.length;
    
    urls.forEach(url => {
        const img = new Image();
        img.onload = function() {
            console.log('预加载成功:', url);
            loadedImages++;
            if (loadedImages === totalImages) {
                callback(true);
            }
        };
        img.onerror = function() {
            console.error('预加载失败:', url);
            loadedImages++;
            if (loadedImages === totalImages) {
                callback(false);
            }
        };
        img.src = url;
    });
}

function getQQAvatarUrl(qqNum) {
    return `https://q1.qlogo.cn/g?b=qq&nk=${qqNum}&s=100`;
}

function isValidQQNumber(qqNum) {
    return /^\d{5,11}$/.test(qqNum);
}

$(document).ready(function() {
    document.body.style.backgroundColor = 'transparent';
    document.body.style.backgroundImage = 'none';
    document.documentElement.style.backgroundColor = 'transparent';
    document.documentElement.style.backgroundImage = 'none';
    
    console.log('页面加载完成，开始预加载头像');

    preloadImages([aiAvatar, userAvatar], function(success) {
        avatarsLoaded = true;
        console.log('头像预加载完成，状态:', success ? '成功' : '部分失败');

        $('#ai-name').text(aiName);

        const aiAvatarElement = $('#ai-avatar');
        aiAvatarElement.removeClass('loading');
        aiAvatarElement.attr('src', aiAvatar);

        aiAvatarElement.on('load', function() {
            console.log('AI头像加载成功:', aiAvatar);
            $(this).removeClass('loading');
            $(this).siblings('.avatar-placeholder').hide();
        }).on('error', function() {
            console.error('AI头像加载失败，显示占位符');
            $(this).addClass('loading');
            $(this).siblings('.avatar-placeholder').show();
        });

        if (aiAvatarElement[0].complete) {
            aiAvatarElement.trigger('load');
        }
    });

    window.addEventListener('message', function(event) {
        const item = event.data;
        
        if (item.type === 'open') {
            if (item.aiAvatar) {
                const newAiAvatar = item.aiAvatar;
                console.log('收到新的AI头像URL:', newAiAvatar);

                preloadImages([newAiAvatar], function(success) {
                    if (success) {
                        aiAvatar = newAiAvatar;
                        const aiAvatarElement = $('#ai-avatar');
                        aiAvatarElement.addClass('loading');
                        aiAvatarElement.attr('src', aiAvatar);

                        if (aiAvatarElement[0].complete) {
                            aiAvatarElement.removeClass('loading');
                            aiAvatarElement.siblings('.avatar-placeholder').hide();
                        }
                        
                        console.log('新AI头像设置成功');
                    } else {
                        console.error('新AI头像加载失败，保留原头像');
                    }
                });
            }
            
            if (item.userAvatar) {
                const newUserAvatar = item.userAvatar;
                console.log('收到新的用户头像URL:', newUserAvatar);

                preloadImages([newUserAvatar], function(success) {
                    if (success) {
                        userAvatar = newUserAvatar;
                        console.log('新用户头像设置成功');
                    } else {
                        console.error('新用户头像加载失败，保留原头像');
                    }
                });
            }

            if (item.qqNumber) {
                qqNumber = item.qqNumber;
                if (isValidQQNumber(qqNumber)) {
                    userAvatar = getQQAvatarUrl(qqNumber);
                    console.log('使用QQ头像:', userAvatar);
                }
            }
            
            if (item.aiName) {
                aiName = item.aiName;
                $('#ai-name').text(aiName);
            }

            document.getElementById('chat-container').classList.remove('hidden');
            document.getElementById('chat-container').classList.add('fade-in');
            document.getElementById('chat-input').focus();

            if ($('#chat-messages .message').length > 0) {
                $('.welcome-message').hide();
            }
        } else if (item.type === 'close') {
            document.getElementById('chat-container').classList.remove('fade-in');
            document.getElementById('chat-container').classList.add('hidden');
            document.getElementById('typing-indicator').classList.add('hidden');
        } else if (item.type === 'aiResponse') {
            if (item.aiAvatar) {
                const newAiAvatar = item.aiAvatar;
                console.log('AI响应中收到新的AI头像URL:', newAiAvatar);

                preloadImages([newAiAvatar], function(success) {
                    if (success) {
                        aiAvatar = newAiAvatar;
                        const aiAvatarElement = $('#ai-avatar');
                        aiAvatarElement.attr('src', aiAvatar);

                        if (aiAvatarElement[0].complete) {
                            aiAvatarElement.removeClass('loading');
                            aiAvatarElement.siblings('.avatar-placeholder').hide();
                        }
                        
                        console.log('AI响应中新头像设置成功');
                    }
                });
            }
            
            if (item.userAvatar) {
                const newUserAvatar = item.userAvatar;
                console.log('AI响应中收到新的用户头像URL:', newUserAvatar);

                preloadImages([newUserAvatar], function(success) {
                    if (success) {
                        userAvatar = newUserAvatar;
                        console.log('AI响应中新用户头像设置成功');
                    }
                });
            }

            showTypingIndicator();

            setTimeout(function() {
                removeTypingIndicator();
                addMessage(false, item.message);
            }, 1000 + Math.min(item.message.length * 20, 2000)); // 根据消息长度调整延迟
        } else if (item.type === 'systemMessage') {
            addSystemMessage(item.message, item.messageType);
        }
    });

    $('#send-button').on('click', function() {
        sendMessage();
    });

    $('#chat-input').on('keypress', function(e) {
        if (e.which === 13) {
            sendMessage();
        }
    });

    document.getElementById('close-button').addEventListener('click', function() {
        closeChat();
    });

    $('#bind-qq-button').on('click', function() {
        openQQBindModal();
    });

    $('#close-modal-button').on('click', function() {
        closeQQBindModal();
    });

    $('#preview-button').on('click', function() {
        const qqNum = $('#qq-number').val().trim();
        previewQQAvatar(qqNum);
    });

    $('#confirm-bind-button').on('click', function() {
        const qqNum = $('#qq-number').val().trim();
        bindQQAvatar(qqNum);
    });
});

function openQQBindModal() {
    $('#qq-bind-modal').removeClass('hidden');
    $('#qq-number').focus();

    if (qqNumber) {
        $('#qq-number').val(qqNumber);
        previewQQAvatar(qqNumber);
    }
}

function closeQQBindModal() {
    $('#qq-bind-modal').addClass('hidden');
    $('#preview-container').addClass('hidden');
    $('#qq-avatar-preview').attr('src', '');
}

function previewQQAvatar(qqNum) {
    if (!isValidQQNumber(qqNum)) {
        $.post('https://fivem_ai/showNotification', JSON.stringify({
            type: 'error',
            message: '请输入有效的QQ号码（5-11位数字）'
        }));
        return;
    }
    
    const previewUrl = getQQAvatarUrl(qqNum);
    const previewImg = $('#qq-avatar-preview');

    $('.preview-container').removeClass('hidden');

    previewImg.addClass('loading');
    previewImg.siblings('.avatar-placeholder').show();

    previewImg.off('load error');

    previewImg.attr('src', previewUrl);

    previewImg.on('load', function() {
        $(this).removeClass('loading');
        $(this).siblings('.avatar-placeholder').hide();

    }).on('error', function() {
        $(this).addClass('loading');
        $(this).siblings('.avatar-placeholder').show();

        $.post('https://fivem_ai/showNotification', JSON.stringify({
            type: 'error',
            message: '无法加载QQ头像，请确认QQ号码是否正确'
        }));
    });
}

function bindQQAvatar(qqNum) {
    if (!isValidQQNumber(qqNum)) {
        $.post('https://fivem_ai/showNotification', JSON.stringify({
            type: 'error',
            message: '请输入有效的QQ号码（5-11位数字）'
        }));
        return;
    }

    const testImage = new Image();
    const testUrl = getQQAvatarUrl(qqNum);
    

    $('#qq-avatar-preview').addClass('loading');
    
    testImage.onload = function() {
        $.post('https://fivem_ai/saveQQBinding', JSON.stringify({
            qqNumber: qqNum
        }), function(response) {
            if (response.success) {
                qqNumber = qqNum;
                userAvatar = response.userAvatar || getQQAvatarUrl(qqNum);

                closeQQBindModal();

                $.post('https://fivem_ai/showNotification', JSON.stringify({
                    type: 'success',
                    message: 'QQ头像绑定成功！'
                }));
            } else {
                $.post('https://fivem_ai/showNotification', JSON.stringify({
                    type: 'error',
                    message: 'QQ绑定失败: ' + (response.message || '未知错误')
                }));
            }
        }).fail(function() {
            $.post('https://fivem_ai/showNotification', JSON.stringify({
                type: 'error',
                message: 'QQ绑定请求失败，请稍后再试'
            }));
        });
    };
    
    testImage.onerror = function() {
        $('#qq-avatar-preview').removeClass('loading');

        $.post('https://fivem_ai/showNotification', JSON.stringify({
            type: 'error',
            message: '无法加载QQ头像，请确认QQ号码是否正确'
        }));
    };

    testImage.src = testUrl;
}

function closeChat() {
    document.getElementById('chat-container').classList.add('fade-out');

    setTimeout(() => {
        document.getElementById('chat-container').classList.remove('fade-out');
        document.getElementById('chat-container').classList.add('hidden');
        
        // 确保背景完全透明
        document.body.style.backgroundColor = 'transparent';
        document.body.style.backgroundImage = 'none';
        document.documentElement.style.backgroundColor = 'transparent';
        document.documentElement.style.backgroundImage = 'none';

        fetch('https://fivem_ai/closeChat', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({})
        });
    }, 300);
}

function sendMessage() {
    const input = $('#chat-input');
    const message = input.val().trim();
    
    if (message !== '') {
        addMessage(true, message);

        input.val('');

        $('.welcome-message').hide();

        $.post('https://fivem_ai/sendMessage', JSON.stringify({
            message: message
        }));

        showTypingIndicator();
    }
}

function showTypingIndicator() {
    if (!isTyping) {
        isTyping = true;
        $('#typing-indicator').removeClass('hidden');
        scrollToBottom();
    }
}

function removeTypingIndicator() {
    isTyping = false;
    $('#typing-indicator').addClass('hidden');
}

function addMessage(isUser, content) {
    console.log('添加消息，用户消息:', isUser, '当前头像URL:', isUser ? userAvatar : aiAvatar);
    
    const messageElement = $('<div class="message ' + (isUser ? 'user-message' : 'ai-message') + '"></div>');

    const messageContent = $('<div class="message-content"></div>');

    const senderName = $('<div class="sender-name">' + (isUser ? '你' : aiName) + '</div>');
    messageContent.append(senderName);

    const messageText = $('<div class="message-text">' + formatMessage(content) + '</div>');
    messageContent.append(messageText);

    const now = new Date();
    const timeString = now.getHours().toString().padStart(2, '0') + ':' + 
                       now.getMinutes().toString().padStart(2, '0');
    const messageTime = $('<div class="message-time">' + timeString + '</div>');
    messageContent.append(messageTime);

    const avatarWrapper = $('<div class="avatar-wrapper"></div>');
    const avatarUrl = isUser ? userAvatar : aiAvatar;
    const backupUrl = isUser ? 'https://i.imgur.com/6MgCm6u.png' : 'https://i.imgur.com/YOJjZlW.png';

    const avatarPlaceholder = $('<div class="avatar-placeholder"><i class="fas fa-' + (isUser ? 'user' : 'robot') + '"></i></div>');
    avatarWrapper.append(avatarPlaceholder);

    const avatar = $('<img class="message-avatar loading" alt="' + (isUser ? '用户' : 'AI') + '头像">');

    avatar.on('load', function() {
        console.log((isUser ? '用户' : 'AI') + '头像加载成功:', avatarUrl);
        $(this).removeClass('loading');
        $(this).siblings('.avatar-placeholder').hide();
    }).on('error', function() {
        console.error((isUser ? '用户' : 'AI') + '头像加载失败，使用备用头像:', backupUrl);
        $(this).attr('src', backupUrl);
    });

    avatarWrapper.append(avatar);

    avatar.attr('src', avatarUrl);

    if (isUser) {
        messageElement.append(messageContent);
        messageElement.append(avatarWrapper);
    } else {
        messageElement.append(avatarWrapper);
        messageElement.append(messageContent);
    }

    $('#chat-messages').append(messageElement);

    if (avatar[0].complete) {
        avatar.removeClass('loading');
        avatar.siblings('.avatar-placeholder').hide();
    }

    scrollToBottom();
}

function formatMessage(message) {
    message = message.replace(/\n/g, '<br>');

    const urlRegex = /(https?:\/\/[^\s]+)/g;
    message = message.replace(urlRegex, function(url) {
        return '<a href="' + url + '" target="_blank">' + url + '</a>';
    });
    
    return message;
}

function scrollToBottom() {
    const chatMessages = document.getElementById('chat-messages');
    chatMessages.scrollTop = chatMessages.scrollHeight;
} 

function addSystemMessage(message, messageType) {
    if (!messageType) messageType = 'info';
    
    console.log('添加系统消息:', message, '类型:', messageType);
    
    const messageElement = $('<div class="message system-message"></div>');

    const messageContent = $('<div class="message-content system-' + messageType + '"></div>');

    let senderName = '系统';
    if (messageType === 'success') senderName = '成功';
    else if (messageType === 'error') senderName = '错误';
    else if (messageType === 'info') senderName = '信息';
    
    const senderNameElement = $('<div class="sender-name">' + senderName + '</div>');
    messageContent.append(senderNameElement);

    const messageText = $('<div class="message-text">' + formatMessage(message) + '</div>');
    messageContent.append(messageText);

    const now = new Date();
    const timeString = now.getHours().toString().padStart(2, '0') + ':' + 
                       now.getMinutes().toString().padStart(2, '0');
    const messageTime = $('<div class="message-time">' + timeString + '</div>');
    messageContent.append(messageTime);

    let iconClass = 'fa-info-circle';
    if (messageType === 'success') iconClass = 'fa-check-circle';
    else if (messageType === 'error') iconClass = 'fa-exclamation-circle';
    
    const iconElement = $('<div class="system-icon"><i class="fas ' + iconClass + '"></i></div>');

    messageElement.append(iconElement);
    messageElement.append(messageContent);

    $('#chat-messages').append(messageElement);
    
    $('.welcome-message').hide();

    scrollToBottom();
} 